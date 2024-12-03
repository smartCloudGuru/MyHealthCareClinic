global class AggregateResultIterable implements Iterable<AggregateResult> {
   global Iterator<AggregateResult> Iterator(){
      return new AggregateResultIterator();
   }
}