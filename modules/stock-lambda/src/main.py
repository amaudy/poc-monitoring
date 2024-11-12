import json
import random

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

def handler(event, context):
    # Randomly select a stock symbol and its description
    symbol = random.choice(list(LSE_STOCKS.keys()))
    description = LSE_STOCKS[symbol]
    
    # Prepare the response
    response_body = {
        "symbol": symbol,
        "description": description,
        "exchange": "London Stock Exchange (LSE)"
    }
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    } 