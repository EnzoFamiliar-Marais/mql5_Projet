//+------------------------------------------------------------------+
//|                                                    Bollinger.mq5 |
//|                                                             Enzo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Enzo"
#property link      "https://www.mql5.com"
#property version   "1.00"


#include <Trade/Trade.mqh> // module de gestion des trades

CTrade trade; // Création de l'objet trade

input group "Bandes de Bollinger"
input ENUM_TIMEFRAMES bbTimeFrame = PERIOD_H4;
input int periodBB = 20;
input double bbStd = 2;
input ENUM_APPLIED_PRICE bbAppPrice= PRICE_CLOSE;


input group "Moyenne Mobile"
input ENUM_TIMEFRAMES maTimeFrame = PERIOD_H4;
input int periodMA = 200;
input ENUM_MA_METHOD maMethod = MODE_SMA;
input ENUM_APPLIED_PRICE maAppPrice = PRICE_CLOSE;

int bbHandle, maHandle;


input group "Paramètres du robot"
input double stopLoss = 200; // Stop loss
input double takeProfit = 40; // Take profit
double SL = stopLoss *10*_Point;
double TP = takeProfit *10*_Point;
input double riskInpct = 0.5; // Risque en pourcentage


double lastCandleLow, lastCandleHigh;

bool isTradeOpen = false;
int bars;



int OnInit()
  {

  bbHandle = iBands(_Symbol,bbTimeFrame,periodBB,1,bbStd,bbAppPrice);
  maHandle = iMA(_Symbol,maTimeFrame,periodMA,0,maMethod,maAppPrice);
  
  return(INIT_SUCCEEDED);
  }


void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {

    int totalBars = iBars(_Symbol, bbTimeFrame);

    if (bars != totalBars){
      bars = totalBars;

      if (PositionsTotal() == 0){
        isTradeOpen = false;
    }
      
    }
      

    lastCandleLow = iLow(_Symbol,bbTimeFrame,2);
    lastCandleHigh = iHigh(_Symbol,bbTimeFrame,2);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double lastCandleClosePrice = iClose(_Symbol,bbTimeFrame,1);

    double bbUpper[], bbLower[], ma[], bbBase[];

    CopyBuffer(bbHandle,BASE_LINE,0,1,bbBase);
    CopyBuffer(bbHandle,UPPER_BAND,0,1,bbUpper);
    CopyBuffer(bbHandle,LOWER_BAND,0,1,bbLower);
    CopyBuffer(maHandle,0,0,1,ma);

    if (lastCandleClosePrice > bbUpper[0]  && bid < ma[0] && !isTradeOpen)
    {
      trade.Sell(positionSizeCalculation(),_Symbol,bid,bid+SL);
      isTradeOpen = true;
    }

    if (bid < bbBase[0] && PositionGetInteger(POSITION_TYPE) == 1){
      trade.PositionClose(PositionGetTicket(0));
      
    }

    if (lastCandleClosePrice < bbLower[0] && ask > ma[0] && !isTradeOpen)
    {
      trade.Buy(positionSizeCalculation(),_Symbol,ask,ask-SL);
      isTradeOpen = true;
    }

    if (ask > bbBase[0] && PositionGetInteger(POSITION_TYPE) == 0)
    {
        trade.PositionClose(PositionGetTicket(0));
    }

    
    //trailingStop();

    
   
  }

double positionSizeCalculation(){

  double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
  double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
  double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
  double riskInCurrency = AccountInfoDouble(ACCOUNT_BALANCE) * riskInpct / 100;

  double riskLotStep = SL / tickSize * lotStep * tickValue;

  double positionSize = MathFloor(riskInCurrency / riskLotStep) * lotStep;

  return positionSize;
}

void trailingStop(){

  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

  for (int i = PositionsTotal() - 1; i >= 0; i--)
    {

      ulong positionTicket = PositionGetTicket(i);

      if (PositionSelectByTicket(positionTicket) && PositionGetInteger(POSITION_TYPE) == 0)
        {
  
          double positionSL = PositionGetDouble(POSITION_SL);
          double positionTP = PositionGetDouble(POSITION_TP);
          double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);

          double pipsInProfit = ask - positionOpenPrice;
          double trailingStop = lastCandleLow + pipsInProfit;

          if (pipsInProfit > 0 && trailingStop > positionSL){

            trade.PositionModify(positionTicket,trailingStop,positionTP);
          }

      
        }

      if (PositionSelectByTicket(positionTicket) && PositionGetInteger(POSITION_TYPE) == 1)
      {
        double positionSL = PositionGetDouble(POSITION_SL);
        double positionTP = PositionGetDouble(POSITION_TP);
        double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);

        double pipsInProfit = bid - positionOpenPrice;
        double trailingStop = lastCandleHigh - pipsInProfit;

        if (pipsInProfit > 0 && trailingStop < positionSL){
          
          trade.PositionModify(positionTicket,trailingStop,positionTP);
        }
      }
    }
}

