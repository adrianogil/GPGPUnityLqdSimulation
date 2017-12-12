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
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag

            #define ISBACKGROUND(P) ((P).x < 0.2)
            #define ISBLOCK(P) ((P) >= 0.2 && (P) < 0.3)
            #define ISWATER(P) ((P).x > 0.3)
            #define UPDATEW(P,T) P = 0.3 + (T)*((P)-0.3)

            #define MAX_IDEAL_WATER_CAPACITY_PER_PIXEL 0.65

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

            half4 onWater(half4 currentPixel,
                          half4 belowPixel,
                          half4 abovePixel,
                          half4 leftPixel,
                          half4 rightPixel)
            {
                if (ISWATER(abovePixel) && currentPixel.x < MAX_IDEAL_WATER_CAPACITY_PER_PIXEL)
                {
                    float currentPixelCapacity = (MAX_IDEAL_WATER_CAPACITY_PER_PIXEL - currentPixel.x) - 0.3;

                    if (abovePixel.x - 0.3 > currentPixelCapacity)
                    {
                        currentPixel.x += currentPixelCapacity;
                    } else {
                        currentPixel.x += (abovePixel.x - 0.3);
                    }
                }
                else {
                    if (belowPixel.x < 0.2) { // Below is background
                        if (currentPixel.x > 0.31){
                            UPDATEW(currentPixel.x, 0.2); // 20% stays
                        } else {
                            currentPixel.x = 0; // Move every drop of water (Turns into Background)
                        }
                    } 
                    else if (belowPixel.x <= 0.3) { // Below is block
                        // Try to flow Into Left and Right Neighboring Cells
                        // if (leftPixel.x <= 0.2 && rightPixel.x <= 0.2)
                        // {
                        //     UPDATEW(currentPixel.x, 0.4); // 40% stays
                        // } else if (leftPixel.x <= 0.2) {
                        //     UPDATEW(currentPixel.x, 0.6); // 60% stays
                        // } else if (rightPixel.x <= 0.2) {
                        //     UPDATEW(currentPixel.x, 0.6); // 60% stays
                        // }
                    } else { // Below is water
                        if (belowPixel.x < MAX_IDEAL_WATER_CAPACITY_PER_PIXEL) {
                            float capacityBelow = (MAX_IDEAL_WATER_CAPACITY_PER_PIXEL - belowPixel.x) - 0.3;
                            if (currentPixel.x - 0.3 < capacityBelow) {
                                currentPixel.x = 0;
                            } else {
                                currentPixel.x -= capacityBelow;
                            }
                        }
                    }
                }
                

                return currentPixel;
            }

            half4 onBackground(half4 currentPixel, 
                               half4 abovePixel,
                               half4 leftPixel,
                               half4 leftistPixel)
            {
                if (abovePixel.x > 0.3) { // Upside pixel is water 
                    if (abovePixel.x > 0.31)
                    {
                        currentPixel.x = 0.3 + 0.8*(abovePixel.x-0.3); // 80% falls
                    } else {
                        currentPixel.x = abovePixel.x; // 100% falls (because it remains only 0.1 of water in top pixel)
                    }
                } 
                // else if (ISWATER(leftPixel.x)) // Left pixel is water
                // {
                //     if (ISBLOCK(leftistPixel.x)) // The leftist is block
                //     {
                //         // 
                //         if (leftPixel.x > 0.31)
                //         {
                //             currentPixel.x = 0.3 + 0.8*(abovePixel.x-0.3); // 80% falls
                //         } else {
                //             currentPixel.x = abovePixel.x; // 100% falls (because it remains only 0.1 of water in top pixel)
                //         }    
                //     }
                // }

                return currentPixel;
            }

            half4 frag(vert_output o) : COLOR
            {
            	half4 texColors[25];
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

                texColors[ 9] = GRABPIXEL(-2,-2);
                texColors[10] = GRABPIXEL(-2,-1);
                texColors[11] = GRABPIXEL(-2, 0);
                texColors[12] = GRABPIXEL(-2, 1);
                texColors[13] = GRABPIXEL(-2, 2);
                texColors[14] = GRABPIXEL( 2,-2);
                texColors[15] = GRABPIXEL( 2,-1);
                texColors[16] = GRABPIXEL( 2, 0);
                texColors[17] = GRABPIXEL( 2, 1);
                texColors[18] = GRABPIXEL( 2, 2);
                texColors[19] = GRABPIXEL(-1,-2);
                texColors[20] = GRABPIXEL( 0,-2);
                texColors[21] = GRABPIXEL( 1,-2);
                texColors[22] = GRABPIXEL(-1, 2);
                texColors[23] = GRABPIXEL( 0, 2);
                texColors[24] = GRABPIXEL( 1, 2);

                if (texColors[4].x > 0.3) { // Current pixel is Water
                     texColors[4] = onWater(texColors[4],  // current
                                            texColors[0],  // below
                                            texColors[5],  // above
                                            texColors[1],  // left
                                            texColors[7]   // right
                                            ); 
            	}

                if (ISBACKGROUND(texColors[4])) { // Current pixel is Background
                    texColors[4] = onBackground(texColors[4],
                                             texColors[5],
                                             texColors[1],
                                             texColors[11]
                                             );	
                }


                return texColors[4];
            }

            ENDCG
        }
    }
}
