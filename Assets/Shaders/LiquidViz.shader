Shader "Custom/LiquidViz"
{
    Properties
    {
        _BackgroundColor("Light Water Color", Color) = (1,1,1,1)
        _BlockColor("Light Water Color", Color) = (1,1,1,1)
        _LightWaterColor("Light Water Color", Color) = (1,1,1,1)
        _DarkWaterColor("Dark Water Color", Color) = (1,1,1,1)
        _MainTex("Liquid State", 2D) = "white"
    }
    Subshader
    {
        Pass
        {
            CGPROGRAM
            // LiquidViz.shader:
            //
            // Water representation:
            //      defines direction flow for current cell
            //   Considering the resulting RGBA:
            //   -> 0.3 < R <= 1.0 -> water
            // Block representation:
            //   -> 0.2 < R < 0.3
            // Background representation:
            //   -> R < 0.2
            //
            #pragma vertex vert
            #pragma fragment frag

            sampler _MainTex;

            float4 _LightWaterColor;
            float4 _DarkWaterColor;
            float4 _BackgroundColor;
            float4 _BlockColor;

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
                half4 colorValue = tex2D(_MainTex, o.uv);

                if (colorValue.x > 0.3)
                {
                    return lerp(_LightWaterColor, _DarkWaterColor, (colorValue.x-0.3)/0.7);
                } else if (colorValue.x < 0.2)
                {
                    return _BackgroundColor;
                } else {
                    return _BlockColor;
                }

                return colorValue;
            }

            ENDCG
        }
    }
}