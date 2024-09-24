Shader "UI/GradientGrayscaleRawImage"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

        // 新增控制灰度渐变的参数
        _GrayPos ("Grayscale Pos", Range(0, 1)) = 0.5
        _GrayRange ("Grayscale Range", Range(0, 0.5)) = 0.05
        _GrayTint ("Gray Tint Color", Color) = (1, 1, 1, 1)
        [Toggle]_GrayTopToBottom("Gray From Top to Bottom", Range(0, 1)) = 1

        [HideInInspector]
        _UVRect("Main UV Rect", vector) = (0, 0, 1, 1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;

            float _GrayPos;
            float _GrayRange;
            float4 _GrayTint;
            float _GrayTopToBottom;

            fixed4 _UVRect;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                OUT.color = v.color * _Color;
                return OUT;
            }

            // 将颜色转换为灰度值
            half3 ConvertToGrayscale(half3 color)
            {
                half grayscaleValue = dot(color, half3(0.3, 0.59, 0.11));
                return half3(grayscaleValue, grayscaleValue, grayscaleValue);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

                // 计算纹理坐标Y的比例
                float y_pos = (IN.texcoord.y / _UVRect.w) - _UVRect.y;

                // 计算渐变过渡的下限和上限
                float lowerBound = _GrayPos - _GrayRange;
                float upperBound = _GrayPos + _GrayRange;

				// 计算渐变因子
                float gradientFactor;
                if(_GrayTopToBottom > 0)                                                            // 从上到下灰化
                    gradientFactor = saturate((upperBound - y_pos) / (upperBound - lowerBound));
                else                                                                                // 从下到上灰化
                    gradientFactor = saturate((y_pos - lowerBound) / (upperBound - lowerBound));

                // 转换为灰色
                half3 grayscaleColor = ConvertToGrayscale(color.rgb);

                // 调整灰度颜色，乘以 _GrayTint
                grayscaleColor *= _GrayTint.rgb;

                // 根据过渡因子在灰色和彩色之间插值
                color.rgb = lerp(grayscaleColor, color.rgb, gradientFactor);

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }
            ENDCG
        }
    }
}
