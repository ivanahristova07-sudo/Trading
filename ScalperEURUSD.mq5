#include <Trade/Trade.mqh>

input double InpLot = 0.1;
input double InpTPMultiplier = 2.0;
input double trailingFactor = 1.0;
input double breakevenFactor = 1.0;

CTrade trade;
int atrHandle;

int OnInit()
  {
   atrHandle = iATR(_Symbol, PERIOD_M1, 14);
   if(atrHandle == INVALID_HANDLE)
      return INIT_FAILED;
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   ManagePosition();
  }

void OpenBuy()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double atr = iATR(_Symbol, PERIOD_M1, 14, 0);
   double sl = ask - atr;
   double tp = ask + atr * InpTPMultiplier;
   trade.Buy(InpLot, _Symbol, ask, sl, tp);
  }

void OpenSell()
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = iATR(_Symbol, PERIOD_M1, 14, 0);
   double sl = bid + atr;
   double tp = bid - atr * InpTPMultiplier;
   trade.Sell(InpLot, _Symbol, bid, sl, tp);
  }

void ManagePosition()
  {
   if(!PositionSelect(_Symbol))
      return;

   double atr = iATR(_Symbol, PERIOD_M1, 14, 0);
   long type = PositionGetInteger(POSITION_TYPE);
   double price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                              : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl = PositionGetDouble(POSITION_SL);
   double tp = PositionGetDouble(POSITION_TP);

   if(type == POSITION_TYPE_BUY)
     {
      double newSL = price - atr * trailingFactor;
      if(sl < newSL)
         trade.PositionModify(_Symbol, newSL, tp);
      if(price - openPrice > atr * breakevenFactor && sl < openPrice)
         trade.PositionModify(_Symbol, openPrice, tp);
     }
   else if(type == POSITION_TYPE_SELL)
     {
      double newSL = price + atr * trailingFactor;
      if(sl == 0 || sl > newSL)
         trade.PositionModify(_Symbol, newSL, tp);
      if(openPrice - price > atr * breakevenFactor && (sl > openPrice || sl == 0))
         trade.PositionModify(_Symbol, openPrice, tp);
     }
  }
