using UnityEngine;

public class MirrorSurface : MonoBehaviour
{
    public Camera cameraTarget;
    [Range(1, 4)]public int reduceRes = 2;

    public bool showPip = true;

    private Camera localCamera;
    private RenderTexture targetTexture;

    private int lastReduceRes;
    private int screenX = -1, screenY = -1;

    void Start()
    {
        GameObject newCamera = Instantiate(cameraTarget.gameObject);
        localCamera = newCamera.GetComponent<Camera>();
        localCamera.allowMSAA = false;
        localCamera.enabled = false;
        localCamera.cullingMask ^= 1 << LayerMask.NameToLayer("NoReflection");
        lastReduceRes = reduceRes;
    }

    private void TextureUpdate()
    {
        if (screenX != Screen.width || screenY != Screen.height || lastReduceRes != reduceRes)
        {
            screenX = Screen.width;
            screenY = Screen.height;
            lastReduceRes = reduceRes;

            if (targetTexture != null)
            {
                targetTexture.Release();
                Destroy(targetTexture);
            }

            targetTexture = new RenderTexture(Screen.width / reduceRes, Screen.height / reduceRes, 16);
            localCamera.targetTexture = targetTexture;
            Shader.SetGlobalTexture("_CameraMirrorTexture", targetTexture);

            //Debug.Log($"Rebuilt render texture to {targetTexture.width}, {targetTexture.height}");
        }
    }

    void OnWillRenderObject()
    {
        if (cameraTarget.transform.position.y <= transform.position.y)
            return;

        TextureUpdate();
        Vector3 targetPos = cameraTarget.transform.position;
        Vector3 targetEuler = cameraTarget.transform.eulerAngles;

        float cameraHeightAbovePlane = cameraTarget.transform.position.y - transform.position.y;
        targetPos.y = transform.position.y - cameraHeightAbovePlane;
        targetEuler.x *= -1.0f;

        localCamera.transform.position = targetPos;
        localCamera.transform.rotation = Quaternion.Euler(targetEuler);

        //https://forum.unity.com/threads/i-need-help-with-using-camera-calculateobliquematrix.483472/
        localCamera.ResetProjectionMatrix();
        Vector4 clipPlane = new Vector4(0.0f, 1.0f, 0.0f, -transform.position.y + 0.1f);
        var mat = localCamera.CalculateObliqueMatrix(Matrix4x4.Transpose(localCamera.cameraToWorldMatrix) * clipPlane);
        localCamera.projectionMatrix = mat;

        localCamera.Render();
    }

    private void OnDestroy()
    {
        targetTexture.Release();
        Destroy(targetTexture);
    }

    private void OnGUI()
    {
        if (!showPip)
            return;

        GUI.Box(new Rect(0.0f, 0.0f, Screen.width / 4.0f + 8, Screen.height / 4.0f + 8), "");
        GUI.DrawTexture(new Rect(4.0f, 4.0f, Screen.width / 4.0f, Screen.height / 4.0f), targetTexture);
    }
}
