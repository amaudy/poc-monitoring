import json
import random
import logging
import os
from datadog_lambda.metric import lambda_metric
from datadog_lambda.wrapper import datadog_lambda_wrapper
from ddtrace import tracer

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# LSE stock symbols with their descriptions
LSE_STOCKS = {
    "HSBA": "HSBC Holdings - Global banking and financial services company",
    "BP": "BP plc - Multinational oil and gas company",
    "SHELL": "Shell plc - Global energy and petrochemical company",
    "AZN": "AstraZeneca - Multinational pharmaceutical company",
    "ULVR": "Unilever - Consumer goods company",
    "RIO": "Rio Tinto - Mining and metals company",
    "GSK": "GlaxoSmithKline - Pharmaceutical company",
    "LLOY": "Lloyds Banking Group - Retail and commercial bank",
    "VOD": "Vodafone Group - Telecommunications company",
    "PRU": "Prudential - Insurance and financial services company"
}

@datadog_lambda_wrapper
def handler(event, context):
    try:
        logger.debug('Event received: %s', event)
        
        environment = os.environ['ENVIRONMENT']
        
        # Add custom metric for invocations
        lambda_metric(
            metric_name='stock_api.invocations',
            value=1,
            tags=[f'environment:{environment}']
        )

        # Add custom span for timing
        with tracer.trace('stock_api.process_request') as span:
            # Randomly select a stock symbol and its description
            symbol = random.choice(list(LSE_STOCKS.keys()))
            description = LSE_STOCKS[symbol]
            
            # Prepare the response
            response_body = {
                "symbol": symbol,
                "description": description,
                "exchange": "London Stock Exchange (LSE)"
            }

            response = {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"  # Add CORS header
                },
                "body": json.dumps(response_body)
            }

        # Add custom metric for successful responses
        lambda_metric(
            metric_name='stock_api.success',
            value=1,
            tags=[f'environment:{environment}']
        )

        logger.debug('Response: %s', response)
        return response

    except Exception as e:
        logger.error('Error occurred: %s', str(e), exc_info=True)
        
        # Add custom metric for errors
        lambda_metric(
            metric_name='stock_api.errors',
            value=1,
            tags=[f'environment:{environment}', f'error_type:{type(e).__name__}']
        )
        
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "error": "Internal server error",
                "message": str(e)
            })
        }
 