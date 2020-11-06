Shader "Unlit/MirrorSurf"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;		
				UNITY_VPOS_TYPE screen_pos : VPOS;
            };

			sampler2D _CameraMirrorTexture;

            v2f vert (appdata v, out float4 pos_out : SV_POSITION)
            {
                v2f o;
                pos_out = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.screen_pos / _ScreenParams.xy;
                float4 col = tex2D(_CameraMirrorTexture, float2(uv.x, 1.0 - uv.y));
                return col;
            }
            ENDCG
        }
    }
}
