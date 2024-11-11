

## Datadog API Key

Create a secret in AWS Secrets Manager with the Datadog API key.

```bash
aws secretsmanager create-secret \
    --name "poc_datadog/datadog/api_key" \
    --description "Datadog API Key" \
    --secret-string "your-api-key-here"
```

Result:

```
{
    "Name": "poc_datadog/datadog/api_key",
    "VersionId": "EXAMPLE1-90ab-cdef-fedc-ba987EXAMPLE"
}
```

Update Datadog API Key in Secrets Manager.

```bash
aws secretsmanager update-secret \
    --secret-id "poc_datadog/datadog/api_key" \
    --secret-string "your-api-key-here"
```