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