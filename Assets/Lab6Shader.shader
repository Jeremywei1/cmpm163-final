Shader "Shaders/Lab6Shader"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _SecTex("Metalness", 2D) = "white" {}
        _ThirTex("Roughness", 2D) = "white" {}
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
            sampler2D _SecTex;
            sampler2D _ThirTex;
			float4 _LightColor0; //Light color, declared in UnityCG
            float4 _SpecularCol;

            // Helper functions---------------------------------------------
            float DistributionGGX(float NdotH, float roughness)
            {
                float a2 = roughness * roughness;
                float NdotH2 = NdotH * NdotH;

                float nom = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = 3.14 * denom * denom;
                
                return nom / denom;
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float nom = NdotV;
                float denom = NdotV * (1.0 - roughness) + roughness;

                return nom / denom;
            }

            float GeometrySmith(float NdotV, float NdotL, float roughness)
            {
                float ggx1 = GeometrySchlickGGX(NdotV, roughness);
                float ggx2 = GeometrySchlickGGX(NdotL, roughness);

                return ggx1 * ggx2;
            }

            float3 FresnelSchlick(float3 F0, float NdotV)
            {
                return F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0);
            }
            //--------------------------------------------------------------
			
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
                // Positions
                float3 P = i.normal;                                    // World space pos
                
                // Directions
                float3 N = normalize(P);                                // Normal
				float3 V = normalize(float3(float4(_WorldSpaceCameraPos.xyz, 1.0) - i.vPos.xyz));
                float3 L = normalize(_WorldSpaceLightPos0.xyz);         // Light vector
                float3 R = reflect(-L, P);                              // Reflect vector
                float3 H = normalize(L+V);
                float4 _Albedo = tex2D(_MainTex, i.uv);
                float3 I = reflect(-V, P);
                float3 Ref = refract(I, P, 0.65);
                
                // Dot products
                float NdotL = max(0, dot(N, L));
                float NdotH = max(0, dot(N, H));
                float NdotV = max(0, dot(N, V));

                // Metalness value
                float metalness = tex2D(_SecTex, i.uv).r;

                // Roughness value
                float roughness = tex2D(_ThirTex, i.uv).r;

                // Material response
                float3 F0 = lerp(_SpecularCol, _Albedo.rgb, metalness);

                // Specular terms
                float D = DistributionGGX(NdotH, roughness);
                float G = GeometrySmith(NdotV, NdotL, roughness);
                float3 F = FresnelSchlick(F0, NdotV);
                float3 SpecularBRDF = (D*G*F)/(4 * NdotV);
    
                //float4 _Albedo = tex2D(_MainTex, i.uv);

                // Diffuse terms
                float3 Diffuse_factor = (1 - F) * (1 - metalness);
                float3 DiffuseBRDF = Diffuse_factor * _Albedo;

                // Cubemap
                // texCUBE(_Cube, I);    
                // texCUBE(_Cube, Ref);                                                                         only refract col
                // texCUBE(_Cube, I) + float4(DiffuseBRDF + SpecularBRDF, 1)                                        refract col+Cook-Torrance
                // lerp(texCUBE(_Cube, R), texCUBE(_Cube, Ref), 0.7) + float4(DiffuseBRDF + SpecularBRDF, 1)          Cook-Torrance + lerp    

                // float4 Color = (float4(DiffuseBRDF, 1.0)+float4(SpecularBRDF, 1.0)) * _LightColor0 * NdotL;

                return (float4(DiffuseBRDF, 1.0)+float4(SpecularBRDF, 1.0)) * _LightColor0 * NdotL;
			}
			ENDCG
		}
    }
}