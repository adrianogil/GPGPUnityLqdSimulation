Shader "Custom/LiquInput"
{
    Properties
    {
        _BlockColor("Block Color", Color) = (1,1,1,1)
        _LightWaterColor("Light Water Color", Color) = (1,1,1,1)
        _DarkWaterColor("Dark Water Color", Color) = (1,1,1,1)
        _NewPos ("New Position", Vector) = (0.5,0.5,0,0)
        _InputType ("Input Type", float) = (0.5,0.5,0,0)
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

            half4 frag(vert_output o) : COLOR
            {
                if (_InputType == 1)
                {
                    if (length(o.uv - _NewPos) < 0.025)
                    {
                        return _LightWaterColor;
                    }
                } else if (_InputType == 0)
                {
                    if (length(o.uv - _NewPos) < _MainTex_TexelSize.x)
                    {
                        return _BlockColor;
                    }
                }

                return tex2D(_MainTex, o.uv);
            }

            ENDCG
        }
    }
}