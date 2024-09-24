/*
 * 灰化过渡效果
*/

using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(RawImage))]
[ExecuteInEditMode]
public class GradientGrayscaleRawImage : MonoBehaviour
{
	private void Awake()
	{
		UpdateShaderUVRect();
	}

	private void OnEnable()
	{
		UpdateShaderUVRect();
	}

	private Material _instMat;

	private Material InstMat
	{
		get
		{
			if (_instMat == null)
			{
				RawImage graphic = GetComponent<RawImage>();
				Material mat = graphic?.material;
				if (mat != null)
				{
					_instMat = Instantiate(mat);
					graphic.material = _instMat;
				}
			}

			return _instMat;
		}
	}

	public void UpdateGrayPos(float grayPos)
	{
		InstMat?.SetFloat("_GrayPos", grayPos);
	}

	public void UpdateGrayRange(float grayRange)
	{
		InstMat?.SetFloat("_GrayRange", grayRange);
	}

	public void UpdateShaderUVRect()
	{
		RawImage rawImage = GetComponent<RawImage>();
		if (rawImage == null || InstMat == null) return;

		Rect rect = rawImage.uvRect;
		Vector4 uvRect = new Vector4(rect.x, rect.y, rect.width, rect.height);

		InstMat.SetVector("_UVRect", uvRect);
	}
}