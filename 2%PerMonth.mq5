#property copyright "Enzo"
#property link      "https://www.mql5.com"
#property version   "1.00"


#include <Trade/Trade.mqh> // module de gestion des trades


CTrade trade; // Création de l'objet trade

datetime LondonOpen, LondonClose;
bool isLondonOpen;

input group "Paramètres du robot"

input int nombreMagique = 262205; // Nombre magique
input double stopLoss = 20; // Stop loss
input double takeProfit = 40; // Take profit

input group "Paramètres de gestion du risque" 
input double riskInpct = 0.5; // Risque en pourcentage

input group "Filter"


double SL = stopLoss *10*_Point;
double TP = takeProfit *10*_Point;
double tradeEnCours = false;




int OnInit()
  {

   return(INIT_SUCCEEDED);
  }




void OnDeinit(const int reason)
  {

   
  }



void OnTick()
  {

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    timestructure();



    if (TimeCurrent() > LondonOpen && TimeCurrent() < LondonClose && !isLondonOpen){
    

      int asianSessionLowestBar = iLowest(_Symbol, PERIOD_H1, MODE_LOW, 10, 1);
      int asianSessionHighestBar = iHighest(_Symbol, PERIOD_H1, MODE_HIGH, 10, 1);

      double asianSessionLow = iLow(_Symbol, PERIOD_H1, asianSessionLowestBar);
      double asianSessionHigh = iHigh(_Symbol, PERIOD_H1, asianSessionHighestBar);

      ObjectCreate(ChartID(),"london Open",OBJ_VLINE,0,LondonOpen,0);
      ObjectCreate(ChartID(),"asian Open",OBJ_VLINE,0,TimeCurrent()-PeriodSeconds(PERIOD_H1)*10,0);

      ObjectCreate(ChartID(),"asianHigh",OBJ_HLINE,0,TimeCurrent()-PeriodSeconds(PERIOD_H1)*10,asianSessionHigh);
      ObjectCreate(ChartID(),"asianLow",OBJ_HLINE,0,TimeCurrent()-PeriodSeconds(PERIOD_H1)*10,asianSessionLow);

      if (tradeEnCours == false)
      {
        trade.BuyStop(positionSizeCalculation(), asianSessionHigh, _Symbol, asianSessionHigh-SL, asianSessionHigh+TP, ORDER_TIME_SPECIFIED, LondonClose);
        trade.SellStop(positionSizeCalculation(), asianSessionLow, _Symbol, asianSessionLow+SL, asianSessionLow-TP, ORDER_TIME_SPECIFIED, LondonClose);
        tradeEnCours = true;
      }
      
      if (PositionsTotal() == 0)
         tradeEnCours = false;

      isLondonOpen = true;
    }

    if (TimeCurrent() > LondonClose && isLondonOpen)
    {
      isLondonOpen = false;
    }

    trailingStop();
    
   
  }

void timestructure()
{
  MqlDateTime structLondonOpen;
  TimeCurrent(structLondonOpen);

  structLondonOpen.hour = 9;
  structLondonOpen.min = 0;
  structLondonOpen.sec = 0;

  LondonOpen = StructToTime(structLondonOpen);



  MqlDateTime structLondonClose;
  TimeCurrent(structLondonClose);

  structLondonClose.hour = 18;
  structLondonClose.min = 0;
  structLondonClose.sec = 0;

  LondonClose = StructToTime(structLondonClose);

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