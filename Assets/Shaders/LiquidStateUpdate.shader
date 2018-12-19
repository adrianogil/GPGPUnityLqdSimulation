Shader "Custom/LiquidStateUpdate" {
	Properties
    {
        _BlockColor("Block Color", Color) = (1,1,1,1)
        _LightWaterColor("Light Water Color", Color) = (1,1,1,1)
        _DarkWaterColor("Dark Water Color", Color) = (1,1,1,1)
        _NewPos ("New Position", Vector) = (0.5,0.5,0,0)
        _InputType ("Input Type", float) = (0.5,0.5,0,0)
        _MainTex("Liquid State", 2D) = "white"
        _FlowTex("Flow Direction", 2D) = "white"
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

            #define TOWNORM(P) (((P) - 0.3)/0.7)
            #define FROMWNORM(P) (0.3 + 0.7*(P))

            #define ISWATER(P) ((P).x > 0.3)
            #define ISBLOCK(P) ((P) >= 0.2 && (P) < 0.3)
            #define ISBACKGROUND(P) ((P).x < 0.2)

            #define ISGOINGDOWN(P) ((P).y > 0)

            #define WATER_GOINGDOWN(P) ((P).y)

            #define WATER(P)  TOWNORM((P).x )
            #define SETWATER(P, W)  (P).x = max(0.3, FROMWNORM((W)));

            #define UPDATEW(P,T) P = 0.3 + (T)*((P)-0.3)

            #define MAX_IDEAL_WATER_CAPACITY_PER_PIXEL 0.65

            sampler _MainTex;
            sampler _FlowTex;
            float4 _MainTex_TexelSize;
            float4 _FlowTex_TexelSize;

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
                          half4 rightPixel,
                          half4 currentFlow,
                          half4 belowFlow,
                          half4 aboveFlow,
                          half4 leftFlow,
                          half4 rightFlow)
            {
                half4 currentState = currentPixel;

                SETWATER(currentState, WATER(currentState) - 
                    (currentFlow.y))
                    // (currentFlow.x + currentFlow.y + currentFlow.z + currentFlow.w) );

                // Reset all water to background
                // currentState = half4(0.0, 0.0, 0.0, 0.0);

                return currentState;
            }

            half4 onBackground(half4 currentPixel,
                              half4 belowPixel,
                              half4 abovePixel,
                              half4 leftPixel,
                              half4 rightPixel,
                              half4 currentFlow,
                              half4 belowFlow,
                              half4 aboveFlow,
                              half4 leftFlow,
                              half4 rightFlow)
            {
                half4 currentState = half4(0.0, 0.0, 0.0, 0.0);

                if (ISWATER(abovePixel) && ISGOINGDOWN(aboveFlow))
                {
                    SETWATER(currentState, WATER_GOINGDOWN(aboveFlow))
                }

                // Reset all background to water
                // currentState = half4(1.0, 0.0, 0.0, 0.0);

                return currentState;
            }

            half4 frag(vert_output o) : COLOR
            {
            	half4 texColors[9], texFlow[9];
                #define GRABPIXEL(px,py) tex2D( _MainTex, o.uv + float2(px * _MainTex_TexelSize.x, py * _MainTex_TexelSize.y))
                #define GRABFLOW(px,py) tex2D( _FlowTex, o.uv + float2(px * _FlowTex_TexelSize.x, py * _FlowTex_TexelSize.y))

                texColors[0] = GRABPIXEL(-1,-1);
                texColors[1] = GRABPIXEL(-1, 0);
                texColors[2] = GRABPIXEL(-1, 1);
                texColors[3] = GRABPIXEL( 0,-1);
                texColors[4] = GRABPIXEL( 0, 0);
                texColors[5] = GRABPIXEL( 0, 1);
                texColors[6] = GRABPIXEL( 1,-1);
                texColors[7] = GRABPIXEL( 1, 0);
                texColors[8] = GRABPIXEL( 1, 1);

                texFlow[0] = GRABFLOW(-1,-1);
                texFlow[1] = GRABFLOW(-1, 0);
                texFlow[2] = GRABFLOW(-1, 1);
                texFlow[3] = GRABFLOW( 0,-1);
                texFlow[4] = GRABFLOW( 0, 0);
                texFlow[5] = GRABFLOW( 0, 1);
                texFlow[6] = GRABFLOW( 1,-1);
                texFlow[7] = GRABFLOW( 1, 0);
                texFlow[8] = GRABFLOW( 1, 1);

                half4 currentColor;

                if (ISWATER(texColors[4])) { // Current pixel is Water
                     currentColor = onWater(texColors[4],  // current
                                            texColors[0],  // below
                                            texColors[5],  // above
                                            texColors[1],  // left
                                            texColors[7],   // right

                                            texFlow[4],  // current flow direction
                                            texFlow[0],  // below flow direction
                                            texFlow[5],  // above flow direction
                                            texFlow[1],  // left flow direction
                                            texFlow[7]   // right flow direction
                                            ); 
            	} else if (ISBACKGROUND(texColors[4]))
                {
                    currentColor = onBackground(texColors[4],  // current
                                                texColors[0],  // below
                                                texColors[5],  // above
                                                texColors[1],  // left
                                                texColors[7],   // right

                                                texFlow[4],  // current flow direction
                                                texFlow[0],  // below flow direction
                                                texFlow[5],  // above flow direction
                                                texFlow[1],  // left flow direction
                                                texFlow[7]   // right flow direction
                                            ); 
                }
                

                return currentColor;
            }

            ENDCG
        }
    }
}
