Shader "Custom/Water/BaseWater2"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}		
		[NoScaleOffset]_NormalTex ("Normal Map", 2D) = "bump" {}
		_NormalAmt("Normal Amount", Range(0.0, 1.0)) = 1.0
		
		_TextureScale ("Texture Scale", Range(1.0, 100.0)) = 10.0
		_NormalScale ("Normal Scale", Range(1.0, 100.0)) = 10.0
		
		_TextureScroll ("Texture Scroll", Float) = 1.0
		_NormalScroll ("Normal Scroll", Float) = 1.0
			
		_Color ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
		
		_SpecAmt ("Specular Amount", Range(0.0, 1.0)) = 1.0
		_SpecGloss ("Specular Gloss", Range(0.0, 2.0)) = 0.8
		
		_ReflBright ("Reflection Brightness", Range(0.0, 1.0)) = 0.5
		_ReflDistort ("Reflection Distort", Float) = 0.1
		
		_FogColor ("Fog Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_FogDensity("Fog Density", Range(0.0, 5.0)) = 0.5
		
		_SubmergedTint ("Submerged Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Tags 
		{ 
			"RenderType" = "Transparent" 
			"Queue" = "Transparent"
			"LightMode" = "ForwardBase"
		}

		GrabPass { "_GrabBG" }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            struct v2f
            {
				//Positions
				float4 w_vertex : TEXCOORD0;
				UNITY_FOG_COORDS(1)				
            };
			
			//Surface and coords
			sampler2D _MainTex;
			sampler2D _NormalTex;
			
			float _NormalAmt;
			
			float _TextureScale;
			float _NormalScale;
			
			float _TextureScroll;
			float _NormalScroll;
			
			float4 _Color;
			
			//Specularity
			float _SpecAmt;
			float _SpecGloss;
            
			//Underwater		
			float4 _FogColor;
			float4 _SubmergedTint;
			float _FogDensity;
			
			//Reflection
			sampler2D _CameraMirrorTexture;
			float _ReflBright;
			float _ReflDistort;
			
			//Depth and BG info
			sampler2D _CameraDepthTexture;
			sampler2D _GrabBG;	
			
            v2f vert (float4 vertex : POSITION, out float4 v_out : SV_POSITION)
            {				
                v_out = UnityObjectToClipPos(vertex);
			
                v2f o;
				o.w_vertex = mul(unity_ObjectToWorld, vertex);

				UNITY_TRANSFER_FOG(o, o.vertex);
				
                return o;
            }
			
			//Partly derived from
			//https://catlikecoding.com/unity/tutorials/flow/looking-through-water/
			float3 underwater_color(float2 screen_uv, float3 world_pos, float3 lighting)
			{
				float3 obj_pos = mul(unity_WorldToObject, world_pos);
				float3 view_pos = UnityObjectToViewPos(obj_pos);
				
				float bg_depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screen_uv));
				float depth_real_dist = abs(bg_depth / normalize(view_pos).z);
				
				float camera_dist = distance(world_pos, _WorldSpaceCameraPos.xyz);

				float dist_through_water = depth_real_dist - camera_dist;
				float fog_amt = 1.0 - saturate(exp2(-_FogDensity * dist_through_water));
				
				float3 bg = tex2D(_GrabBG, screen_uv).rgb;
					
				return lerp(bg.rgb * _SubmergedTint.rgb, _FogColor.rgb * lighting, fog_amt);
			}

            float3 frag (v2f i, UNITY_VPOS_TYPE screen_pos : VPOS) : SV_Target
            {				
				//Scrolling				
				float2 scroll1 = float2(_Time.x * 0.934, _Time.x * -1.134) - 0.743;
				float2 scroll2 = float2(_Time.x * -0.189, _Time.x * 1.788) + 0.442;
			
				//Texture coords
				float2 world_uv = i.w_vertex.xz;
				
				float2 color_uv1 = (world_uv + scroll1 * _TextureScroll) / _TextureScale;
				float2 color_uv2 = (world_uv + scroll2 * _TextureScroll) / _TextureScale;
				
				float2 normal_uv1 = (world_uv + scroll1 * _NormalScroll) / _NormalScale;
				float2 normal_uv2 = (world_uv + scroll2 * _NormalScroll) / _NormalScale;
			
				//Color blend
				float4 color1 = tex2D(_MainTex, color_uv1);
				float4 color2 = tex2D(_MainTex, color_uv2);
				float4 color_mix = lerp(color1, color2, 0.5) * _Color; //temp?	
				
				//Normal blend
				float4 normal1 = tex2D(_NormalTex, normal_uv1);
				float4 normal2 = tex2D(_NormalTex, normal_uv2);
				float3 normal_mix = UnpackNormal(lerp(normal1, normal2, 0.5)); //temp
			
				//Surface lighting
				float3 lighting_normal = normalize(lerp(float3(0.0, 0.0, 1.0), normal_mix, _NormalAmt));
				float3 lighting = saturate(dot(lighting_normal.xzy, _WorldSpaceLightPos0.xyz)) * _LightColor0.rgb;					
				float3 lit_color = color_mix.rgb * lighting;
			
				//Screen UVs
				float2 screen_uv = screen_pos.xy / _ScreenParams.xy;
						
				//Underwater color
				float3 underwater = underwater_color(screen_uv, i.w_vertex, lighting);		
				
				//Reflection
				float2 distort = normal_mix.xy * _ReflDistort;
				float3 reflection = tex2D(_CameraMirrorTexture, float2(screen_uv.x, 1.0 - screen_uv.y) + distort).rgb;	
				
				//Final color
				float3 final_color = lit_color + (underwater + reflection * _ReflBright) * (1.0 - color_mix.a);				
                UNITY_APPLY_FOG(i.fogCoord, final_color);			
				return final_color;
            }
            ENDCG
        }
    }
}
