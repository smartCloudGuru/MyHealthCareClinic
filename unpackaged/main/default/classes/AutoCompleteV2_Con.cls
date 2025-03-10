/*
*    CreatedDate : 6-Oct-2013
*    Class Name : AutoCompleteV2_Con
**/
public class AutoCompleteV2_Con {

    public String labelFieldVar{ get; set; }
    public String valueFieldVar{ get; set; }
    public String sObjVal{get;set;}
    public Integer randomJsIden{get;set;}
    public Object cacheField{get;private set;} 
    
    private Object targetFieldVar;
    
    public AutoCompleteV2_Con(){
        randomJsIden = getRandomNumber(1000000);
        sObjVal='Account';
        labelFieldVar='Name';
        valueFieldVar='Id';
    }
    
    /*Dummy setter Method*/
    public void setCacheField(Object cacheField){}
    
    public void setTargetFieldVar(Object targetFieldVar){
        
        if(targetFieldVar != this.targetFieldVar){
            cacheField = getCacheFieldValue(targetFieldVar);
            this.targetFieldVar = targetFieldVar;
           
        }
        
    }
    
    public Object getTargetFieldVar(){
        return targetFieldVar;
    }
    
    private Object getCacheFieldValue(Object targetFieldVar){
        Object retVal = targetFieldVar;
        if(targetFieldVar!=null){
            for(sObject sObj : Database.query('SELECT '+valueFieldVar+','+labelFieldVar+' FROM '+sObjVal+' WHERE '+valueFieldVar+' =:targetFieldVar')){
                retVal = sObj.get(labelFieldVar);
                break;
            }
        }
        
        return retVal;
    }

    
    /*
    *Random number generator to change the js function name if multiple components us
    ***/
    private Integer getRandomNumber(Integer size){
        Double d = Math.random() * size;
        return d.intValue();
    }
    
    /*
    *This method queries data according to the passed parameters
    ***/
    @RemoteAction
    public static List<AutoCompleteData> getData(String sObjVal,String labelFieldVar,String valueFieldVar,String param, string whereClause, string listId2NotInclude){
        List<AutoCompleteData> AutoCompleteDatas = new List<AutoCompleteData>();
        if(param != null && param != ''){        
            param = String.escapeSingleQuotes(param);
            for( Sobject sObj : Database.query('SELECT '+valueFieldVar+','+labelFieldVar+' FROM '+sObjVal+' WHERE '+labelFieldVar+' LIKE \'%'+param+'%\' '+listId2NotInclude)){
                AutoCompleteDatas.add(new AutoCompleteData(sObj.get(valueFieldVar),sObj.get(labelFieldVar)));
            }        
            return AutoCompleteDatas;
        }
        param = String.escapeSingleQuotes(param);
        for( Sobject sObj : Database.query('SELECT '+valueFieldVar+','+labelFieldVar+' FROM '+sObjVal+' '+whereClause +' '+listId2NotInclude)){
            AutoCompleteDatas.add(new AutoCompleteData(sObj.get(valueFieldVar),sObj.get(labelFieldVar)));
        }  
        return AutoCompleteDatas;        
    }
    
    public class AutoCompleteData{
        public String id;
        public String text;
        
        public AutoCompleteData(Object id, Object text){
            this.id = String.valueOf(id);
            this.text = String.valueOf(text);
        }
    }

    
}