// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "FX/Water (Basic)" {
Properties {
	_horizonColor ("Horizon color", COLOR)  = ( .172 , .463 , .435 , 0)
	_WaveScale ("Wave scale", Range (0.02,0.15)) = .07
	[NoScaleOffset] _ColorControl ("Reflective color (RGB) fresnel (A) ", 2D) = "" { }
	[NoScaleOffset] _BumpMap ("Waves Normalmap ", 2D) = "" { }


	[HideInInspector]_DropPos_1("Drop Position 1", Vector) = (0, 0, 0, 0)
	[HideInInspector]_DropPos_2("Drop Position 2", Vector) = (0, 0, 0, 0)
	[HideInInspector]_DropPos_3("Drop Position 3", Vector) = (0, 0, 0, 0)
	[HideInInspector]_NowTime_1("NowTime 1", float) = 0
	[HideInInspector]_NowTime_2("NowTime 2", float) = 0
	[HideInInspector]_NowTime_3("NowTime 3", float) = 0
	[HideInInspector]_SplashScale_1("SplashScale 1", float) = 1
	[HideInInspector]_SplashScale_2("SplashScale 2", float) = 1
	[HideInInspector]_SplashScale_3("SplashScale 3", float) = 1


	[KeywordEnum(START, STOP)]_WATER_SPLASH("water splash", float) = 1

	[Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor", float) = 0
	[Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor", float) = 0

	WaveSpeed ("Wave speed (map1 x,y; map2 x,y)", Vector) = (19,9,-16,-7)
	}

CGINCLUDE

#include "UnityCG.cginc"

uniform float4 _horizonColor;

uniform float4 WaveSpeed;
uniform float _WaveScale;
uniform float4 _WaveOffset;

struct appdata {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4  texcoord : TEXCOORD0; 
};

struct v2f {
	float4 pos : SV_POSITION;
	float2 bumpuv[2] : TEXCOORD0;
	float3 viewDir : TEXCOORD2;
	float2 uv : TEXCOORD4; 
	float4 wdposition : TEXCOORD5;
	UNITY_FOG_COORDS(3)
};

v2f vert(appdata v)
{
	v2f o;
	float4 s;

	o.pos = UnityObjectToClipPos(v.vertex);

	// scroll bump waves
	float4 temp;
	float4 wpos = mul (unity_ObjectToWorld, v.vertex);
	temp.xyzw = wpos.xzxz * _WaveScale + _WaveOffset;
	o.bumpuv[0] = temp.xy * float2(.4, .45);
	o.bumpuv[1] = temp.wz;
	o.uv = v.texcoord.xy;
	o.wdposition = wpos;

	// object space view direction
	o.viewDir.xzy = normalize( WorldSpaceViewDir(v.vertex) );

	//UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

ENDCG


Subshader {
	Tags { "RenderType"="Opaque" "Queue" = "Transparent"}
	Blend [_SrcFactor] [_DstFactor]
	BlendOp Add
	Pass {

CGPROGRAM
#pragma multi_compile _WATER_SPLASH_START _WATER_SPLASH_STOP
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fog
#define PI 3.141592653

sampler2D _BumpMap;
sampler2D _ColorControl;
float4  _DropPos_1;
float _NowTime_1;
float4  _DropPos_2;
float _NowTime_2;
float4  _DropPos_3;
float _NowTime_3;
float _SplashScale_1;
float _SplashScale_2;
float _SplashScale_3;

float3 GetNewNormal(float3 fpos, float3 droppos, float nowtime, float scale){
             float dis = length(fpos - droppos);
            if(dis > scale)
               dis = 0;
            float dropFrac = 1 - (_Time.y - nowtime);
            float final = dropFrac * sin(clamp((dropFrac - 1.0 + dis/scale) * 9, 0.0, 4.0) * PI);
            return  float3(dis/scale * final, dis/scale * final , 1);
}

half4 frag( v2f i ) : COLOR
{
	half3 bump1 = UnpackNormal(tex2D( _BumpMap, i.bumpuv[0] )).rgb;
	half3 bump2 = UnpackNormal(tex2D( _BumpMap, i.bumpuv[1] )).rgb;
	half3 bump = (bump1 + bump2) * 0.5;
	float3 mnormal_1 = float3 (0, 0, 0);
	float3 mnormal_2 = float3 (0, 0, 0);
	float3 mnormal_3 = float3 (0, 0, 0);

	#ifdef _WATER_SPLASH_START
	       mnormal_1 = GetNewNormal(i.wdposition.xyz, _DropPos_1.xyz, _NowTime_1, _SplashScale_1);
	       mnormal_2 = GetNewNormal(i.wdposition.xyz, _DropPos_2.xyz, _NowTime_2, _SplashScale_2);
	       mnormal_3 = GetNewNormal(i.wdposition.xyz, _DropPos_3.xyz, _NowTime_3, _SplashScale_3);
    #endif
	
	half fresnel = dot( i.viewDir, bump + mnormal_1 + mnormal_2 + mnormal_3);

	half4 water = tex2D( _ColorControl, float2(fresnel,fresnel) );
	
	half4 col;
	col.rgb = lerp( water.rgb, _horizonColor.rgb, water.a );
	col.a = _horizonColor.a;

	//UNITY_APPLY_FOG(i.fogCoord, col);
	return col;
}
ENDCG
	}
}

}
