#property copyright "Enzo"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input int magicNumber = 1234;

enum calcMode {
  Lineaire,
  Exponentielle
};

input group "Martingale"
input ENUM_TIMEFRAMES rsiTimeFrame = PERIOD_H4;
input int rsiPeriod = 14;
input ENUM_APPLIED_PRICE rsiAppliedPrice = PRICE_CLOSE;

input group "Parametres"
input double positionSize = 0.5;
input double lotMultiplier = 2;
input int gridTradeNumber = 5;
input double inputGridSpread = 20;
input double inputTakeProfit = 20;
input calcMode lotCalcMode = 0; // 0 = Linéaire, 1 = Exponentielle Mode de calcul du lot

int rsiHandle;
double lotSize;

int lastGridStep;


double gridSpread = inputGridSpread*_Point*10;
double takeProfit = inputTakeProfit*_Point*10;

int OnInit()
{

  trade.SetExpertMagicNumber(magicNumber);
  rsiHandle = iRSI(_Symbol, rsiTimeFrame, rsiPeriod, rsiAppliedPrice);
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
  
}

void OnTick()
{
  double rsi[];

  CopyBuffer(rsiHandle, 0, 0,2,rsi);

  if(rsi[0] => 30 && rsi[1] < 30){

    if(!isTradeOpen()){
      executeBuyGrid();
   }
  }

  if (rsi[0] <= 70 && rsi[1] > 70){

    if(!isTradeOpen()){
      executeSellGrid();
    }
  }

  if(!isTradeOpen()){
   deleteAllOrders();
  }

  if(lastGridStep != PositionsTotal()){
    
    lastGridStep = PositionsTotal();
    
    if(isTradeOpen() && PositionsTotal() > 1){
      updateTakeProfit();
    }

  }

}

void executeBuyGrid(){

  double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

  trade.Buy(positionSize,_Symbol,ask,0,ask+takeProfit);

  for(int i = gridTradeNumber-1; i > 0; i--){

    

    if(lotCalcMode == 0)
      lotSize =  NormalizeDouble(positionSize*lotMultiplier*i,2);

    else if (lotCalcMode == 1){
      lotSize =  NormalizeDouble(positionSize*MathPow(lotMultiplier,i),2);
    }
    
    double entryPrice = NormalizeDouble(ask-gridSpread*i,_Digits);

    trade.BuyLimit(lotSize,entryPrice,_Symbol,0,ask+takeProfit);

  }

}

void executeSellGrid(){
  
  double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  
  trade.Sell(positionSize,_Symbol,bid,0,bid-takeProfit);

  for(int i = gridTradeNumber-1; i > 0; i--){



    if(lotCalcMode == 0)
      lotSize = NormalizeDouble(positionSize*lotMultiplier*i,2);

    else if (lotCalcMode == 1){
      lotSize =  NormalizeDouble(positionSize*MathPow(lotMultiplier,i),2);
    }

    double entryPrice = NormalizeDouble(bid+gridSpread*i,_Digits);
    
    trade.SellLimit(lotSize,entryPrice,_Symbol,0,bid-takeProfit);
    
  }
}

bool isTradeOpen(){
  
  for(int i = PositionsTotal()-1; i >= 0; i--){

    ulong positionTicket = PositionGetTicket(i);

    if(PositionSelectByTicket(positionTicket)){

      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber){
        return true;
      }
    }
  }
  return false;
}

void deleteAllOrders(){


 for(int i = OrdersTotal()-1; i >= 0; i--){
   
   ulong orderTicket = OrderGetTicket(i);
   
   if(OrderSelect(orderTicket)){   
      trade.OrderDelete(orderTicket);
   }
 }
}

void updateTakeProfit(){

  double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  
  for(int i = PositionsTotal()-1; i >= 0; i--){
   
    ulong positionTicket = PositionGetTicket(i);


   
    if(PositionSelectByTicket(positionTicket)){

      if(PositionGetInteger(POSITION_TYPE) == 0 && PositionGetInteger(POSITION_MAGIC) == magicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol){

        double newTakeProfit = NormalizeDouble(ask+takeProfit,_Digits);

        trade.PositionModify(positionTicket,0,newTakeProfit);

      
      }

      if(PositionGetInteger(POSITION_TYPE) == 1 && PositionGetInteger(POSITION_MAGIC) == magicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol){
        
        double newTakeProfit = NormalizeDouble(bid-takeProfit,_Digits);

        trade.PositionModify(positionTicket,0,newTakeProfit);
      }
    }
  }  
}