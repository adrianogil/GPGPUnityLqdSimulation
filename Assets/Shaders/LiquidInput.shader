Shader "Custom/LiquInput"
{
    Properties
    {
        _BlockColor("Block Color", Color) = (1,1,1,1)
        _LightWaterColor("Light Water Color", Color) = (1,1,1,1)
        _DarkWaterColor("Dark Water Color", Color) = (1,1,1,1)
        _NewPos ("New Position", Vector) = (0.5,0.5,0,0)
        _InputType ("Input Type", float) = (0.5,0.5,0,0)
        _InputAreaSize ("Input Area Size", float) = (0.025,0,0,0)
        _MainTex("Liquid State", 2D) = "white"
    }
    Subshader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler _MainTex;
            float4 _MainTex_TexelSize;

            float _InputType;
            float _InputAreaSize;

            float2 _NewPos;
            float4 _BlockColor;
            float4 _LightWaterColor;
            float4 _DarkWaterColor;

            struct vert_input
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct vert_output
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            vert_output vert(vert_input i)
            {
                vert_output o;

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.uv = i.uv;

                return o;
            }

            float4 frag(vert_output o) : COLOR
            {
                float4 tex = tex2D(_MainTex, o.uv);

                if (abs(_InputType - 1) < 0.1)
                {
                    if (tex.x >= 0.2 && tex.r < 0.3)
                    {
                        return tex;
                    }

                    float dist = length(o.uv - _NewPos);

                    if (dist < 0.025)
                    {
                        float4 newColorValue = float4(0,0,0,1);

                        float a = dist/0.025;
                        newColorValue.x = (1.0/255.0) + 0.3 + 0.7*(1 - a);
                        newColorValue.yz = 0;

                        return newColorValue;
                    }
                } else if (abs(_InputType) < 0.1)
                {
                    if (length(o.uv - _NewPos) < _MainTex_TexelSize.x)
                    {
                        return float4(0.25,0,0,1);
                    }
                }

                return tex;
            }

            ENDCG
        }
    }
}