using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class LiquidSimulation : MonoBehaviour {

    public RenderTexture liquidState;
    public int stateSizeX = 200, stateSizeY = 200;

	[Header("Color States")]
    public Color blockColor;
    public Color lightWaterColor;
    public Color darkWaterColor;
	public Color backgroundColor;

    public int stateUpdatePerFrame = 3;

    public Material GPGPUMaterial;
    public Material GPGPUInputMaterial;
    private MeshCollider collider;

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
	}

    void UpdateState()
    {
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

		Texture2D initStateTexture = new Texture2D (stateSizeX, stateSizeY);

        Color backgroundColorData = new Color(0f,0f,0f,1f);
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
            }
        }
		initStateTexture.Apply();

		Graphics.Blit (initStateTexture, liquidState);

		MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
		if (meshRenderer != null) {
			meshRenderer.material.mainTexture = liquidState;
            meshRenderer.material.SetColor("_LightWaterColor", lightWaterColor);
            meshRenderer.material.SetColor("_DarkWaterColor", darkWaterColor);
            meshRenderer.material.SetColor("_BackgroundColor", backgroundColor);
            meshRenderer.material.SetColor("_BlockColor", blockColor);
		}
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
}

#if UNITY_EDITOR
[CustomEditor(typeof(LiquidSimulation))]
public class LiquidSimulationEditor : Editor {

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        LiquidSimulation editorObj = target as LiquidSimulation;

        if (editorObj == null) return;

        if (GUILayout.Button("Initialize"))
        {
            editorObj.InitState();
        }
    }

}
#endif

