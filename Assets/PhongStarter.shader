// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Shaders/PhongStarter"
{
	Properties{
		_MainTex("Albedo", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		[MaterialToggle] _Ambient("Ambient", Float) = 0
		[MaterialToggle] _Diffuse("Diffuse", Float) = 0
		[MaterialToggle] _Specular("Specular", Float) = 0
        _Intensity("Intensity", Range(0,1)) = 0
		_Shininess("Shininess", float) = 0
		_SpecularCol("Specular Color", Color) = (1,1,1,1)
	}

	SubShader
	{
		//PASS 1		
		Pass 
		{
			Tags { "LightMode" = "ForwardBase" } // Since we are doing forward rendering and we want to get directional light
			// Tags { "LightMode" = "ForwardAdd"} For point lights. One pass per light
			// Blend One One //Turn on additive blending if you have more than one point light (optional)
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc" // Predefined variables and helper functions Unity provides

            sampler2D _MainTex;
			float4 _LightColor0; //Light color, declared in UnityCG
			float4 _Color;
            float _Ambient;
            float _Diffuse;
            float _Specular;
            float _Intensity;
            float _Shininess;
            float _SpecularCol;
            
			
			struct VertexShaderInput
			{
				float4 vertex : POSITION;
				float2 uv	  : TEXCOORD0;
                float4 normal : NORMAL;
			};

			struct VertexShaderOutput
			{
				float4 pos    : SV_POSITION;
				float2 uv     : TEXCOORD0;
                float4 normal : TEXCOORD2;       //worldSpaceNormal
                float4 vPos   : TEXCOORD3;     //worldSpaceVertextPos
			};

			VertexShaderOutput vert(VertexShaderInput v)
			{
				VertexShaderOutput o;	
                o.normal = float4(UnityObjectToWorldNormal(v.normal), 1);
                o.vPos   = mul(unity_ObjectToWorld, v.vertex);
				o.uv     = v.uv;
				o.pos    = UnityObjectToClipPos(v.vertex);
				return o;
			}

			float4 frag(VertexShaderOutput i):SV_TARGET
			{
                float3 P = i.normal;                                    // World space pos
                float3 N = normalize(P);                         // Normal
				float3 V = normalize(float3(float4(_WorldSpaceCameraPos.xyz, 1.0) - i.vPos.xyz));
                float3 L = normalize(_WorldSpaceLightPos0.xyz);     // Light vector
                float3 R = reflect(-L, P);                       // Reflect vector

                float4 output;
				output = tex2D(_MainTex, i.uv);

                float4 Albedo;
                Albedo = output * _Color;

                float3 ambientLight;
                ambientLight = _Ambient * UNITY_LIGHTMODEL_AMBIENT * 5;
            
                float3 diffuseLight;
                diffuseLight = _Diffuse * Albedo * _LightColor0 * max(dot(_WorldSpaceLightPos0, P), 0.0);

                //float3 specularLight;
                //specularLight = _Specular * _LightColor0 * _SpecularCol * _Intensity * pow(max(dot(R, V), 0.0), _Shininess);

				float3 specularLight = _Intensity * _SpecularCol  * pow(max(dot(R, V), 0.0), _Shininess);

				float3 lightFinal = (ambientLight + diffuseLight + specularLight);

                return float4(lightFinal * Albedo, 1.0);
			}
			ENDCG
		}

		//// PASS 2	
		//Pass
		//{
		//	//Tags { "LightMode" = "ForwardBase" } // Since we are doing forward rendering and we want to get directional light
		//	Tags { "LightMode" = "ForwardAdd"} //For point lights. One pass per light
		//	// Blend One One //Turn on additive blending if you have more than one point light (optional)
		//	CGPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag

		//	#include "UnityCG.cginc" // predefined variables and helper functions Unity provides

		//	float4 _LightColor0; //Light color, declared in UnityCG
		//	sampler2D _MainTex;
		//	float4 _Color;

		//	struct VertexShaderInput
		//	{
		//		float4 vertex : POSITION;
		//		float2 uv	  : TEXCOORD0;

		//	};

		//	struct VertexShaderOutput
		//	{
		//		float4 pos:SV_POSITION;
		//		float2 uv: TEXCOORD0;

		//	};

		//	VertexShaderOutput vert(VertexShaderInput v)
		//	{
		//		VertexShaderOutput o;
		//		o.uv = v.uv;
		//		o.pos = UnityObjectToClipPos(v.vertex);
		//		return o;
		//	}

		//	float4 frag(VertexShaderOutput i) :SV_TARGET
		//	{
		//		float4 output;
		//		output = tex2D(_MainTex, i.uv);
		//		return output * _LightColor0;
		//	}
		//	ENDCG
		//}
	}
}
