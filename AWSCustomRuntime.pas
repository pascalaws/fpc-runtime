program AWSCustomRuntime;

{$mode objfpc}{$H+}

uses
  sysutils, classes, fphttpclient, fpjson, jsonparser;

var
  awsHost, awsBaseUrl, awsResponseUrl, awsErrorUrl, awsRequestId, awsEventBody: String;
  httpClient: TFPHTTPClient;
  awsEvent, awsError: TJSONObject;

const
  // Current AWS runtime API version
  APIVERSION = '2018-06-01';

begin
  awsEvent := TJSONObject.Create;
  awsError := TJSONObject.Create;
  httpClient := TFPHttpClient.Create(Nil);
  try
    // Get the runtime api awsHost
    awsHost := GetEnvironmentVariable('AWS_LAMBDA_RUNTIME_API');

    // Create the base url
    awsBaseUrl := 'http://' + awsHost + '/' + APIVERSION + '/runtime/invocation/';

    while true do begin
      try
        // Get the event
        awsEventBody := httpClient.get(awsBaseUrl + 'next');

        // Get the JSON data and set the TJSONObject
        awsEvent := TJSONObject(GetJSON(awsEventBody));

        // Pretty-print the event (Should be visible in logwatch)
        WriteLn(awsEvent.FormatJSON);

        // Get the request id, used when responding
        awsRequestId := trim(httpClient.ResponseHeaders.Values['Lambda-Runtime-AWS-Request-Id']);

        // Create the response url
        awsResponseUrl := awsBaseUrl + awsRequestId + '/response';

        // Create error url
        awsErrorUrl := awsBaseUrl + awsRequestId + '/error';

        // Send successful event response
        TFPHttpClient.SimpleFormPost(awsResponseUrl, awsEventBody);

        {
          Error responses should follow the JSON format below, see here for details
          https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html#runtimes-api-invokeerror

          Example
          -------

          awsError.Strings['errorMessage'] := 'Something went horribly wrong';
          awsError.Strings['errorType'] := 'InvalidEventDataException';

          TFPHttpClient.SimpleFormPost(awsErrorUrl, awsError.AsJSON);
        }
      except
      end;
    end;

  finally
    httpClient.Free;
    awsEvent.Free;
    awsError.Free;
  end;
end.
