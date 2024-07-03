//+------------------------------------------------------------------+
//|                                                    Bollinger.mq5 |
//|                                                             Enzo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Enzo"
#property link      "https://www.mql5.com"
#property version   "1.04"

#include <Trade/Trade.mqh> // module de gestion des trades

CTrade trade; // Création de l'objet trade

input group "Bandes de Bollinger"
input ENUM_TIMEFRAMES bbTimeFrame = PERIOD_H4;
input int periodBB = 20;
input double bbStd = 2;
input ENUM_APPLIED_PRICE bbAppPrice = PRICE_CLOSE;

input group "Moyenne Mobile"
input ENUM_TIMEFRAMES maTimeFrame = PERIOD_H4;
input int periodMA = 200;
input ENUM_MA_METHOD maMethod = MODE_SMA;
input ENUM_APPLIED_PRICE maAppPrice = PRICE_CLOSE;

input group "Paramètres MACD"
input ENUM_TIMEFRAMES macdTimeFrame = PERIOD_H4;
input int fastEMAPeriod = 12;
input int slowEMAPeriod = 26;
input int signalPeriod = 9;

int bbHandle, maHandle, rsiHandle, macdHandle;

input group "Paramètres du robot"
input double stopLoss = 200; // Stop loss
double SL;
input double riskInpct = 0.5; // Risque en pourcentage

double lastCandleLow, lastCandleHigh;

int magicNumber = 220905;

int bars;

int OnInit()
{
    bbHandle = iBands(_Symbol, bbTimeFrame, periodBB, 1, bbStd, bbAppPrice);
    maHandle = iMA(_Symbol, maTimeFrame, periodMA, 0, maMethod, maAppPrice);
    macdHandle = iMACD(_Symbol, macdTimeFrame, fastEMAPeriod, slowEMAPeriod, signalPeriod, PRICE_CLOSE);
    trade.SetExpertMagicNumber(magicNumber);

    if (bbHandle == INVALID_HANDLE || maHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE || macdHandle == INVALID_HANDLE)
    {
        Print("Erreur lors de la création des indicateurs");
        return (INIT_FAILED);
    }

    SL = stopLoss * _Point;

    return (INIT_SUCCEEDED);
}

void OnTick()
{
    int totalBars = iBars(_Symbol, bbTimeFrame);

    if (bars != totalBars)
    {
        bars = totalBars;
        
    }

    lastCandleLow = iLow(_Symbol, bbTimeFrame, 2);
    lastCandleHigh = iHigh(_Symbol, bbTimeFrame, 2);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double lastCandleClosePrice = iClose(_Symbol, bbTimeFrame, 1);

    double bbUpper[], bbLower[], ma[], bbBase[], rsi[], macd[], macdSignal[]; 


    if (CopyBuffer(bbHandle, BASE_LINE, 0, 1, bbBase) <= 0 ||
        CopyBuffer(bbHandle, UPPER_BAND, 0, 1, bbUpper) <= 0 ||
        CopyBuffer(bbHandle, LOWER_BAND, 0, 1, bbLower) <= 0 ||
        CopyBuffer(maHandle, 0, 0, 1, ma) <= 0 ||
        CopyBuffer(rsiHandle, 0, 0, 1, rsi) <= 0 || 
        CopyBuffer(macdHandle, MAIN_LINE, 1, 2, macd) ||
        CopyBuffer(macdHandle, SIGNAL_LINE, 1, 2, macdSignal))
        


    {
        Print("Erreur lors de la copie des buffers");
        return;
    }

    // Conditions de vente
    if (lastCandleClosePrice > bbUpper[0] && ask > ma[0]  && macd[1] > macdSignal[1] && macd[0] < macdSignal[0] && !isTradeOpen())
    {
        if (trade.Sell(positionSizeCalculation(), _Symbol, bid, bid + SL))
        
        {
            Print("Erreur lors de l'ouverture de la position SELL: ", GetLastError());
        }
    }

    // Condition pour clôturer une vente
    if (bid < bbBase[0])
    {
        ClosePosition(POSITION_TYPE_SELL);
    }

    // Conditions d'achat
    if (lastCandleClosePrice < bbLower[0] && bid < ma[0]  && macd[1] < macdSignal[1] && macd[0] > macdSignal[0] && !isTradeOpen())
    {
        if (trade.Buy(positionSizeCalculation(), _Symbol, ask, ask - SL))
        {
            Print("Erreur lors de l'ouverture de la position BUY: ", GetLastError());
        }
    }

    // Condition pour clôturer un achat
    if (ask > bbBase[0])
    {
        ClosePosition(POSITION_TYPE_BUY);
    }
}

double positionSizeCalculation()
{
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double riskInCurrency = AccountInfoDouble(ACCOUNT_BALANCE) * riskInpct / 100;

    double riskLotStep = SL / tickSize * lotStep * tickValue;

    double positionSize = MathFloor(riskInCurrency / riskLotStep) * lotStep;

    return positionSize;
}

void ClosePosition(int positionType)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelect(Symbol()) && PositionGetInteger(POSITION_TYPE) == positionType)
        {
            ulong positionTicket = PositionGetInteger(POSITION_TICKET);
            if (!trade.PositionClose(positionTicket))
            {
                Print("Erreur lors de la fermeture de la position: ", positionTicket, " Erreur: ", GetLastError());
            }
        }
    }
}

bool isTradeOpen()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong positionTicket = PositionGetTicket(i);
        if (PositionSelectByTicket(positionTicket))
        {
            if (PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber)
                return true;
        }
    }
    return false;
}
