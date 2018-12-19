Shader "Custom/LiquidFlowUpdate" {
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
            // LiquidDirectionFlow.shader
            //      defines direction flow for current cell
            //   Considering the resulting RGBA:
            //   -> R > 0 -> flow goes right
            //   -> G > 0 -> flow goes down
            //   -> B > 0 -> flow goes left
            //   -> A > 0 -> flow goes up
            //
            // Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
            #pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag

            #define MIN3(A,B,C) (min((A), min((B), (C))))

            #define ISWATER(P) ((P).x > 0.3)
            #define ISBLOCK(P) ((P) >= 0.2 && (P) < 0.3)
            #define ISBACKGROUND(P) ((P).x < 0.2)


            #define WATER(P)  (((P).x-0.3)/0.7)

            
            
            #define UPDATEW(P,T) P = 0.3 + (T)*((P)-0.3)

            #define MAX_IDEAL_WATER_CAPACITY_PER_PIXEL 0.65

            // The maximum amount of water that is going to fell down each update
            #define WATER_MAX_FALL_VELOCITY (0.01)

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

            float4 onWater(float4 currentPixel,
                          float4 belowPixel,
                          float4 abovePixel,
                          float4 leftPixel,
                          float4 rightPixel)
            {

                float4 flowDirection = float4(0.0, 0.0, 0.0, 0.0);

                float currentWater = WATER(currentPixel);

                float waterToFlow = 0.0;

                // Rule #1: Flowing Into Bottom Neighboring Cell
                if (ISBACKGROUND(belowPixel))
                {
                    waterToFlow = min(currentWater, WATER_MAX_FALL_VELOCITY);
                    currentWater = currentWater - waterToFlow;

                    // WATER GOES DOWN
                    flowDirection.y = waterToFlow;
                    
                } else if (ISWATER(belowPixel))
                {
                    float belowWater = WATER(belowPixel);

                    if (currentWater > belowWater){
                        waterToFlow = MIN3(currentWater, WATER_MAX_FALL_VELOCITY, 1.0 - belowWater);
                        currentWater = currentWater - waterToFlow;

                        // WATER GOES DOWN
                        flowDirection.y = waterToFlow;
                    }
                } else {
                    // WATER DOESNOT GO DOWN
                    flowDirection.y = 0;
                }

                // Rule #2: Flowing Into Left and Right Neighboring Cells
                return flowDirection;
            }

            float4 frag(vert_output o) : COLOR
            {
                float4 texColors[25];
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

                float4 nextColor = float4(0,0,0,0);

                if (ISWATER(texColors[4])) { // Current pixel is Water
                     nextColor = onWater(texColors[4],  // current
                                            texColors[0],  // below
                                            texColors[5],  // above
                                            texColors[1],  // left
                                            texColors[7]   // right
                                            );
                }

                return nextColor;
            }

            ENDCG
        }
    }
}
