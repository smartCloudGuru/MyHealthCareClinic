public class MainWrapper{
    public WrapperForHeader objWPH {get;set;}
    public list<WrapperForDetail> objlstWFDs {get;set;}  
    public WrapperForTotal objWFT {get;set;}
     
    public class WrapperForHeader{
        public string headerItem {get;set;}
        public string headerDay1 {get;set;}
        public string headerDay2 {get;set;}
        public string headerDay3 {get;set;}
        public string headerDay4 {get;set;}
        public string headerDay5 {get;set;}
        public string headerDay6 {get;set;}
        public string headerDay7 {get;set;}
        public string headerTotal {get;set;}
    }
    public class WrapperForDetail{
        public string detailItem {get;set;}
        public string detailDay1 {get;set;}
        public string detailDay2 {get;set;}
        public string detailDay3 {get;set;}
        public string detailDay4 {get;set;}
        public string detailDay5 {get;set;}
        public string detailDay6 {get;set;}
        public string detailDay7 {get;set;}
        public integer detailTotal {get;set;} 
        public WrapperForDetail(){
            this.detailItem = '';
            this.detailDay1 = '0'; 
            this.detailDay2 = '0';
            this.detailDay3 = '0';
            this.detailDay4 = '0';
            this.detailDay5 = '0';
            this.detailDay6 = '0';
            this.detailDay7 = '0'; 
            this.detailTotal = 0; 
        }
    }
    public class WrapperForTotal{
        public integer totalDay1 {get;set;}
        public integer totalDay2 {get;set;}
        public integer totalDay3 {get;set;}
        public integer totalDay4 {get;set;}
        public integer totalDay5 {get;set;}
        public integer totalDay6 {get;set;}
        public integer totalDay7 {get;set;}
        public integer additionOfTotal {get;set;}
        public WrapperForTotal(){
            this.totalDay1 = 0;
            this.totalDay2 = 0;
            this.totalDay3 = 0;
            this.totalDay4 = 0;
            this.totalDay5 = 0;
            this.totalDay6 = 0;
            this.totalDay7 = 0;
            this.additionOfTotal = 0;
        }
    }  
}