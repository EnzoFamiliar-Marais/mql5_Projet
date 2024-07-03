//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                                                             Enzo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Enzo"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh> // module de gestion des trades

CTrade trade; // Création de l'objet trade

input group "Paramètres du robot"
input int nombreMagique = 262205; // Nombre magique
input double stopLoss = 20; // Stop loss
input double takeProfit = 40; // Take profit

input group "Paramètres de gestion du risque" 
input double riskInpct = 0.5; // Risque en pourcentage

input group "Filter"
double SL = stopLoss * 10 * _Point;
double TP = takeProfit * 10 * _Point;

input group "Paramètres MACD"
input ENUM_TIMEFRAMES macdTimeFrame = PERIOD_H4;
input int fastEMAPeriod = 12;
input int slowEMAPeriod = 26;
input int signalPeriod = 9;

int magicNumber = 45240;

int macdHandle;
int barsTotal;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   macdHandle = iMACD(_Symbol, macdTimeFrame, fastEMAPeriod, slowEMAPeriod, signalPeriod, PRICE_CLOSE);
   trade.SetExpertMagicNumber(magicNumber);
   barsTotal = iBars(_Symbol, macdTimeFrame);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    

    int bars = iBars(_Symbol, macdTimeFrame); 

    if (bars > barsTotal)
    {
      barsTotal = bars;
       
      double macd[];
      CopyBuffer(macdHandle, MAIN_LINE, 1, 2, macd);

      double macdSignal[];
      CopyBuffer(macdHandle, SIGNAL_LINE, 1, 2, macdSignal);
      
      if (macd[1] > macdSignal[1] && macd[0] < macdSignal[0] && !isTradeOpen())
      {
          double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
          trade.Buy(riskInpct, _Symbol, ask, ask - SL, ask + TP);   
      }
      else if (macd[1] < macdSignal[1] && macd[0] > macdSignal[0] && !isTradeOpen())
      {
          double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
          trade.Sell(riskInpct, _Symbol, bid, bid + SL, bid - TP);
      }
    }
  }
//+------------------------------------------------------------------+

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
