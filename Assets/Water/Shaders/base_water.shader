Shader "Custom/Water/BaseWater"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}		
		[NoScaleOffset]_NormalTex ("Normal Map", 2D) = "bump" {}
		_TextureScale ("Texture Scale", Range(1.0, 100.0)) = 10.0
		_NormalScale ("Normal Scale", Range(1.0, 100.0)) = 10.0
			
		_Color ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
		
		_SpecAmt ("Specular Amount", Range(0.0, 1.0)) = 1.0
		_SpecGloss ("Specular Gloss", Range(0.0, 2.0)) = 0.8
		
		_ReflDistort ("Reflection Distort", Float) = 0.1
		
		_FogColor ("Fog Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_FogDensity("Fog Density", Range(0.0, 5.0)) = 0.5
		
		_SubmergedTint ("Submerged Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Tags 
		{ 
			"Queue" = "Transparent" 
		}
		
		GrabPass { "_BG" }

		CGPROGRAM
		
		#pragma surface surf Water noambient alpha finalcolor:reset
		#pragma target 3.0
		
		sampler2D _MainTex;
		sampler2D _NormalTex;
		float _TextureScale;
		float _NormalScale;
		
		float4 _Color;
		
		float4 _FogColor;
		float4 _SubmergedTint;
		float _FogDensity;
		
		float _SpecAmt;
		float _SpecGloss;

		//Depth and BG info
		sampler2D _CameraDepthTexture;
		float4 _CameraDepthTexture_TexelSize;
		sampler2D _BG;
		
		//Reflection
		float _ReflDistort;
		sampler2D _CameraMirrorTexture;

		float4 LightingWater(SurfaceOutput surface, float3 viewDir, UnityGI gi)
		{
			float3 lambert = surface.Albedo * gi.light.color * max(dot(gi.light.dir, surface.Normal), 0);
			float4 result = float4(lambert + surface.Albedo * gi.indirect.diffuse, surface.Alpha);

			float3 h = normalize (gi.light.dir + viewDir);
			float nh = max(0.0, dot (surface.Normal, h));
			float spec = pow(nh, surface.Gloss * 256.0) * surface.Specular;		
			result.rgb += spec * gi.light.color;
			
			return result;
		}
		
		void LightingWater_GI(SurfaceOutput surface, UnityGIInput data, inout UnityGI gi)
		{
			gi = UnityGlobalIllumination (data, 1.0, surface.Normal);
		}
		
		float3 underwater_color(float2 screen_uv, float3 world_pos)
		{
			float3 obj_pos = mul(unity_WorldToObject, world_pos);
			float3 view_pos_2 = UnityObjectToViewPos(obj_pos);
			
			float bg_depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screen_uv));
			float depth_real_dist = abs(bg_depth / normalize(view_pos_2).z);
			
			float camera_dist = distance(world_pos, _WorldSpaceCameraPos.xyz);

			float dist_through_water = depth_real_dist - camera_dist;
			float fog_amt = 1.0 - saturate(exp2(-_FogDensity * dist_through_water));
			
			float3 bg = tex2D(_BG, screen_uv).rgb;
				
			return lerp(bg.rgb * _SubmergedTint.rgb, _FogColor.rgb, fog_amt);
		}
		
		struct Input
		{
			float3 worldPos;
			float4 screenPos;
			float3 viewDir;
		};
		
		void surf(Input input, inout SurfaceOutput output)
		{
			float2 screen_uv = input.screenPos.xy / max(0.001, input.screenPos.w);
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_CameraDepthTexture_TexelSize.y < 0) 
				screen_uv.y = 1 - screen_uv.y;
			#endif
		
			float2 uv = input.worldPos.xz / _TextureScale;
		
			float2 scroll1 = float2(_Time.x * 0.934, _Time.x * -1.134);
			float2 scroll2 = float2(_Time.x * -0.189, _Time.x * 1.788);
		
			float4 color1 = tex2D(_MainTex, uv + scroll1 * 0.05) * _Color;
			float4 color2 = tex2D(_MainTex, uv + scroll2 * 0.05) * _Color;
			output.Albedo = lerp(color1.rgb, color2.rgb, 0.5) * _Color.a;
			
			float2 nrm_uv = input.worldPos.xz / _NormalScale;
			
			float4 normal1 = tex2D(_NormalTex, nrm_uv * 0.988 + scroll1 * 0.1);
			float4 normal2 = tex2D(_NormalTex, nrm_uv * 1.023 + scroll2 * 0.1);
			output.Normal = UnpackNormal(lerp(normal1, normal2, 0.5));
			
			float3 underwater = underwater_color(screen_uv, input.worldPos);
			
			float distort = output.Normal * _ReflDistort;
			float3 reflection = tex2D(_CameraMirrorTexture, float2(screen_uv.x, 1.0 - screen_uv.y) + distort).rgb;	
			
			output.Alpha = _Color.a;
			output.Emission = (underwater + reflection * 0.5) * (1.0 - _Color.a);
			output.Specular = _SpecAmt;
			output.Gloss = _SpecGloss;
			
			//output.Specular = _SpecTint;
			//output.Smoothness = _SpecGloss;
		}
		
		void reset(Input input, SurfaceOutput o, inout fixed4 color) 
		{
			color.a = 1;
		}
		
		ENDCG
    }
}