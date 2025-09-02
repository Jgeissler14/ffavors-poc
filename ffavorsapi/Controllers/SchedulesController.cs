using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Mime;
// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace ffavorsapi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SchedulesController : ControllerBase
    {

        // GET: api/<SchedulesController>
        [HttpGet("{site_id}")]
        public string Get(int site_id = 1)
        {
            // This method should return a list of schedules.
            //get schedules from RDS database
            StreamReader reader = new StreamReader("schedules.json");
            string json = reader.ReadToEnd();
            reader.Close();
            return json;
        }

        // GET api/<SchedulesController>/5
        //[HttpGet("{id}")]
        //public string Get(int id)
        //{
        //    return "value";
        //}

        // POST api/<SchedulesController>
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/<SchedulesController>/5
        [HttpPut("{id}/{status}/{comment}")]
        public void Put(int id, string status, string comment)
        {
            //return Ok("Updated record in RDS");
        }

        // DELETE api/<SchedulesController>/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
        [HttpGet("GetFile/{reportName}/{parameters}")]
        public HttpResponseMessage GenerateReportPDF(string reportName, string parameters)
        {
            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(ReadFile.FileStreamToByteArray("FFAVS907.pdf"))
            };
            result.Content.Headers.ContentDisposition =
                new System.Net.Http.Headers.ContentDispositionHeaderValue("attachment")
                {
                    FileName = "FFAVS907.pdf"
                };
            result.Content.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/pdf");

            return result;
            //return File("FFAVS907.pdf", "application/pdf");
        }
    }
}
