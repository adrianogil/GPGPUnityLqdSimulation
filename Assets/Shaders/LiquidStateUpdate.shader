Shader "Custom/LiquidStateUpdate" {
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
            	half4 texColors[9];
                #define GRABPIXEL(px,py) tex2D( _MainTex, o.uv + float2(px * _MainTex_TexelSize.x, py * _MainTex_TexelSize.y))

                texColors[0] = GRABPIXEL(-1,-1);
                texColors[1] = GRABPIXEL(-1, 0);
                texColors[2] = GRABPIXEL(-1, 1);
                texColors[3] = GRABPIXEL( 0,-1);
                texColors[4] = GRABPIXEL( 0, 0);
                texColors[5] = GRABPIXEL( 0, 1);
                texColors[6] = GRABPIXEL( 1,-1);
                texColors[7] = GRABPIXEL( 1, 0);
                texColors[8] = GRABPIXEL( 1, 1);

                if (texColors[4].x > 0.3) { // Current pixel is Water
                	if (texColors[3].x <= 0.2) { // Below is background
                		if (texColors[4].x > 0.31){
                			texColors[4].x = 0.3 + 0.2*(texColors[4].x-0.3); // 20% stays
                		} else {
                			texColors[4].x = 0; // Move every drop of water
                		}
            		} else if (texColors[3].x > 0.2 && texColors[3].x <= 0.3) { // Below is block
	            		// Try to flow Into Left and Right Neighboring Cells
	            		if (texColors[0].x <= 0.2 && texColors[6].x <= 0.2)
	            		{
	            			texColors[4].x = 0.3 + 0.4*(texColors[4].x-0.3); // 40% stays
	        			} else if (texColors[0].x <= 0.2) {
	        				texColors[4].x = 0.3 + 0.6*(texColors[4].x-0.3); // 60% stays
	    				} else if (texColors[6].x <= 0.2) {}
	    					texColors[4].x = 0.3 + 0.6*(texColors[4].x-0.3); // 60% stays
    				} else { // Below is water
    					if (texColors[3].x < 0.9) {
    						float capacityBelow = 0.9 - texColors[3].x;
    						if (texColors[4].x - 0.3 < capacityBelow) {
    							texColors[4].x = 0;
							} else {
								texColors[4].x -= capacityBelow;
							}
    					}
    				}
            	}

                if (texColors[4].x <= 0.2) { // Current pixel is Background
                	if (texColors[5].x > 0.3) { //
                		if (texColors[5].x > 0.31)
                		{
                			texColors[4].x = 0.3 + 0.8*(texColors[5].x-0.3); // 80% falls
                		} else {
                			texColors[4].x = texColors[5].x; // 90% falls
                		}
                	}
                }


                return texColors[4];
            }

            ENDCG
        }
    }
}
