using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public enum TextureGridType
{
    StateGrid,
    VizGrid
}

public class LiquidSimulation : MonoBehaviour {

    public RenderTexture liquidState, liquidflow;
    public int stateSizeX = 200, stateSizeY = 200;

	[Header("Color States")]
    public Color blockColor;
    public Color lightWaterColor;
    public Color darkWaterColor;
	public Color backgroundColor;

    public int stateUpdatePerFrame = 8;

    public Material GPGPUMaterial;
    public Material GPGPUFlowMaterial;
    public Material GPGPUInputMaterial;
    private MeshCollider collider;

    [HideInInspector]
    public bool alreadyStarted = false;

    [HideInInspector]
    public Color newColor = Color.black;

    [HideInInspector]
    public int pixelPosX;

    [HideInInspector]
    public int pixelPosY;

    [HideInInspector]
    public int currentGridPosX;

    [HideInInspector]
    public int currentGridPosY;

    [HideInInspector]
    public Texture2D textureGameState;


	// Use this for initialization
	void Start () {
		InitState();

        collider = GetComponent<MeshCollider>();
	}

	// Update is called once per frame
	void Update () {
		if (Input.GetMouseButton (0)) {
			VerifyInputArea (1f);
		} else if (Input.GetMouseButton (1)) {
			VerifyInputArea (0f);
		}

        for (int i = 0; i < stateUpdatePerFrame; i++)
        {
            UpdateState();
        }

        UpdateInternalTexture();
	}

    public void UpdateState()
    {
        Graphics.Blit (liquidState, liquidflow, GPGPUFlowMaterial);
        Graphics.Blit (liquidState, liquidState, GPGPUMaterial);
    }

	public void VerifyInputArea(float inputType)
	{
		Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
		RaycastHit hit;
		if (collider.Raycast(ray, out hit, 100.0F)) {
			//				Debug.Log(hit.point);
			Vector2 uv = GetUVFromHitPoint(hit.point);
			Debug.Log("UV: (" + uv.x + "," + uv.y + ")");

			GPGPUInputMaterial.SetVector("_NewPos", uv);
			GPGPUInputMaterial.SetFloat ("_InputType", inputType);
			GPGPUInputMaterial.SetColor ("_BlockColor", blockColor);
			GPGPUInputMaterial.SetColor("_LightWaterColor", lightWaterColor);
			GPGPUInputMaterial.SetColor("_DarkWaterColor", darkWaterColor);

			Graphics.Blit (liquidState, liquidState, GPGPUInputMaterial);
		}
	}

    public void InitState()
    {
        liquidState = new RenderTexture (stateSizeX, stateSizeY, 16, RenderTextureFormat.ARGB32);
		liquidflow = new RenderTexture (stateSizeX, stateSizeY, 16, RenderTextureFormat.ARGB32);

        Texture2D initStateTexture = new Texture2D (stateSizeX, stateSizeY);
		Texture2D initFlowStateTexture = new Texture2D (stateSizeX, stateSizeY);

        Color backgroundColorData = new Color(0f,0f,0f,1f);
        Color noFlowData = new Color(0f,0f,0f,0f);
        Color blockColorData = new Color(0.25f,0f,0f,1f);

        for (int x = 0; x < stateSizeX; x++)
        {
            for (int y = 0; y < stateSizeY; y++)
            {
                if (x == 0 || x == stateSizeX - 1 || y == 0 || y == stateSizeY - 1)
                {
					initStateTexture.SetPixel(x,y, blockColorData);
                }
                else {
                    initStateTexture.SetPixel(x,y, backgroundColorData);
                }
                initFlowStateTexture.SetPixel(x,y, noFlowData);
            }
        }
		initStateTexture.Apply();
        initFlowStateTexture.Apply();

        Graphics.Blit (initStateTexture, liquidState);
		Graphics.Blit (initFlowStateTexture, liquidflow);

        GPGPUMaterial.SetTexture("_FlowTex", liquidflow);

        textureGameState = new Texture2D (stateSizeX, stateSizeY);

        UpdateInternalTexture();

		MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
		if (meshRenderer != null) {
			meshRenderer.material.mainTexture = liquidState;
            meshRenderer.material.SetColor("_LightWaterColor", lightWaterColor);
            meshRenderer.material.SetColor("_DarkWaterColor", darkWaterColor);
            meshRenderer.material.SetColor("_BackgroundColor", backgroundColor);
            meshRenderer.material.SetColor("_BlockColor", blockColor);
		}

        alreadyStarted = true;
    }

    private void UpdateInternalTexture()
    {
        RenderTexture.active = liquidState;

        textureGameState.ReadPixels(new Rect(0, 0, stateSizeX, stateSizeY), 0, 0);
        textureGameState.Apply();
    }

    public Vector2 GetUVFromHitPoint(Vector3 point)
    {
        Vector2 uv;

        Vector3 centerPosition = transform.position;
		Vector3 size = transform.localScale;

		Vector3 initialPosition = centerPosition - 0.5f * size;
		Vector3 relativePosition = point - initialPosition;

		uv.x = relativePosition.x / size.x;
		uv.y = relativePosition.y / size.y;

        return uv;
    }

    public Color GetPixelColor(int x, int y, TextureGridType gridType)
    {
        if (gridType == TextureGridType.StateGrid)
            return textureGameState.GetPixel(x,y);

        return Color.black;
    }
}

#if UNITY_EDITOR
[CustomEditor(typeof(LiquidSimulation))]
public class LiquidSimulationEditor : Editor {

    private const int maxInnerWidth = 250;
    private const int maxInnerHeight = 80;

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        LiquidSimulation editorObj = target as LiquidSimulation;

        if (editorObj == null) return;

        if (GUILayout.Button("Initialize"))
        {
            editorObj.InitState();
        }

        if (editorObj.alreadyStarted)
        {
            if (GUILayout.Button("Update State")) {
                editorObj.UpdateState();
            }
        }
    }

    public void OnDebugGrid(LiquidSimulation editorObj, TextureGridType gridType,
        int sizeX, int sizeY)
    {
        editorObj.currentGridPosX = EditorGUILayout.IntField("Grid Start Position X:", editorObj.currentGridPosX);
        editorObj.currentGridPosY = EditorGUILayout.IntField("Grid Start Position Y:", editorObj.currentGridPosY);

        // Number of Cells
        int cols = 25, rows = 15;

        float gridItemWidth = maxInnerWidth/(1.0f * cols);

        // GUI.Box(new Rect(5,5, 800, 800), "Colors");
        // GUILayout.BeginArea(new Rect(10, 10, 700, 700));
        GUILayout.BeginVertical();
        for (int y = 0; y < rows && y < sizeX - editorObj.currentGridPosY; y++)
        {
            GUILayout.BeginHorizontal();
            for (int x = 0; x < cols && x < sizeY - editorObj.currentGridPosX; x++)
            {
                    EditorGUILayout.ColorField(GUIContent.none,
                                               // colorGrid.GetColor(x, y),
                                               editorObj.GetPixelColor(x+editorObj.currentGridPosX,
                                                                       y+editorObj.currentGridPosY,
                                                                       gridType),
                                               false, true, false, null, GUILayout.Width(gridItemWidth));

            }
            GUILayout.EndHorizontal();
        }
        GUILayout.EndVertical();
        // GUILayout.EndArea();
    }

}
#endif

