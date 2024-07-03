//+------------------------------------------------------------------+
//|                                                      RSI&MMA.mq5 |
//|                                                             Enzo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Enzo"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input int magicNumber = 2209;

input group "RSI&MMA";
input double positionsize = 0.5;
input double takeprofit = 200;
input double stoploss = 200;


double TP = takeprofit * 10 * _Point;
double SL = stoploss * 10 * _Point;

int ema21Handle, ema55Handle, rsiHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ema21Handle = iMA(_Symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);
   ema55Handle = iMA(_Symbol, PERIOD_H1, 55, 0, MODE_EMA, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
   if (ema21Handle == INVALID_HANDLE || ema55Handle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE)
   {
      Print("Error initializing indicators");
      return(INIT_FAILED);
   }

   trade.SetExpertMagicNumber(magicNumber);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   double ema21[], ema55[], rsi[];
   if (CopyBuffer(ema21Handle, 0, 0, 2, ema21) <= 0 || CopyBuffer(ema55Handle, 0, 0, 2, ema55) <= 0 || CopyBuffer(rsiHandle, 0, 0, 2, rsi) <= 0)
   {
      Print("Error copying indicator buffers");
      return;
   }

   if (ema21[1] < ema55[1] && ema21[0] > ema55[0] && rsi[1] < 30 && rsi[0] > 30 && !isTradeOpen()){
      trade.Buy(positionsize, _Symbol, ask, ask - SL, ask + TP);
   }

   if (ema21[1] > ema55[1] && ema21[0] < ema55[0] && rsi[1] > 70 && rsi[0] < 70 && !isTradeOpen()){
      trade.Sell(positionsize, _Symbol, bid, bid + SL, bid - TP);
   }
   
   }

   //trailingStop();

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

void trailingStop()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minTrailingDistance = 200 * _Point; // Distance minimale entre le SL initial et le nouveau SL

   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (PositionSelect(_Symbol))
      {
         ulong positionTicket = PositionGetInteger(POSITION_TICKET);
         long positionType = PositionGetInteger(POSITION_TYPE);
         double positionSL = PositionGetDouble(POSITION_SL);
         double positionTP = PositionGetDouble(POSITION_TP);
         double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double initialSL = positionType == POSITION_TYPE_BUY ? positionOpenPrice - SL : positionOpenPrice + SL;

         double pipsInProfit = positionType == POSITION_TYPE_BUY ? ask - positionOpenPrice : positionOpenPrice - bid;
         double trailingStop = positionType == POSITION_TYPE_BUY ? positionOpenPrice + pipsInProfit - minTrailingDistance : positionOpenPrice - pipsInProfit + minTrailingDistance;

         if ((positionType == POSITION_TYPE_BUY && pipsInProfit > 0 && trailingStop > positionSL && trailingStop > initialSL) ||
             (positionType == POSITION_TYPE_SELL && pipsInProfit > 0 && trailingStop < positionSL && trailingStop < initialSL))
         {
            if (!trade.PositionModify(positionTicket, trailingStop, positionTP))
            {
               Print("Erreur lors de la modification de la position: ", positionTicket, " Erreur: ", GetLastError());
            }
         }
      }
   }
}
