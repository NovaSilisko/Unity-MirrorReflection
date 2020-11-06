using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class CameraDepthEnable : MonoBehaviour
{
    private void OnEnable()
    {
        var camera = GetComponent<Camera>();

        if (camera != null)
        {
            camera.depthTextureMode = DepthTextureMode.Depth;
        }
    }
}
