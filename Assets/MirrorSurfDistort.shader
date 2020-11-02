Shader "Custom/MirrorSurfDistort"
{
    Properties
    {
		_BumpMap ("Normal map", 2D) = "bump" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Distortion ("Distortion", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Lambert fullforwardshadows
        #pragma target 3.0

        sampler2D _BumpMap;
		sampler2D _CameraMirrorTexture;
		float _Distortion;

        struct Input
        {
            float2 uv_BumpMap;
			float4 screenPos;
        };
		
        void surf (Input IN, inout SurfaceOutput o)
        {
            float3 n = UnpackNormal(tex2D (_BumpMap, IN.uv_BumpMap));
            o.Normal = n;
			o.Albedo = 0.0;
			
			float2 uv = IN.screenPos.xy / IN.screenPos.w;
			float fade = smoothstep(0.0, 1.0, sin(_Time.y * 1.5) * 0.5 + 0.5);
			float2 distort = o.Normal.xy * _Distortion * fade;
			
			float4 mirror = tex2D(_CameraMirrorTexture, float2(uv.x, 1.0 - uv.y) + distort);
			
			o.Emission = mirror;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
