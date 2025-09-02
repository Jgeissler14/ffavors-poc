namespace ffavorsapi
{
    public class ReadFile
    {
        public static byte[] FileStreamToByteArray(string filePath)
        {
            using (FileStream fs = File.OpenRead(filePath))
            {
                using (MemoryStream ms = new MemoryStream())
                {
                    fs.CopyTo(ms); // Copies the content of FileStream to MemoryStream
                    return ms.ToArray(); // Converts the MemoryStream to a byte array
                }
            }
        }

    }
}
