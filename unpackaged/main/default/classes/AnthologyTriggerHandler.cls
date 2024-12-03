/**
 * @author Zoran Zunko
 *
 * @group TriggerHandler
 *
 * @group-content ../../ApexDocContent/TriggerHandler
 *
 * @date 2/9/16
 */
public with sharing class AnthologyTriggerHandler {

    public class AnthologyTriggerContext {
        public Schema.SObjectType triggerObject { get; set; }
        public System.TriggerOperation triggerOperation { get; set; }
        public Boolean isExecuting { get; set; }
        public List<SObject> newList { get; set; }
        public Map<Id, SObject> newMap { get; set; }
        public List<SObject> oldList { get; set; }
        public Map<Id, SObject> oldMap { get; set; }

        public AnthologyTriggerContext(
                Schema.SObjectType triggerObject,
                System.TriggerOperation triggerOperation,
                Boolean isExecuting,
                List<SObject> newList,
                Map<Id, SObject> newMap,
                List<SObject> oldList,
                Map<Id, SObject> oldMap) {

            this.triggerObject = triggerObject;
            this.triggerOperation = triggerOperation;
            this.isExecuting = isExecuting;
            this.newList = newList;
            this.newMap = newMap;
            this.oldList = oldList;
            this.oldMap = oldMap;
        }
    }

    public interface Delegate {
        void prepareBefore();
        void prepareAfter();

        void beforeInsert(SObject o);
        void beforeUpdate(SObject old, SObject o);
        void beforeDelete(SObject o);

        void afterInsert(SObject o);
        void afterUpdate(SObject old, SObject o);
        void afterDelete(SObject o);
        void afterUndelete(SObject o);

        void finish();

        void prepareBeforeInProgress();
        void prepareAfterInProgress();

        void beforeInsertInProgress(SObject o);
        void beforeUpdateInProgress(SObject old, SObject o);
        void beforeDeleteInProgress(SObject o);

        void afterInsertInProgress(SObject o);
        void afterUpdateInProgress(SObject old, SObject o);
        void afterDeleteInProgress(SObject o);
        void afterUndeleteInProgress(SObject o);

        void finishInProgress();

        Map<String, String> getTriggerContext();
        AnthologyTriggerContext getAnthologyTriggerContext();
        void setAnthologyTriggerContext(AnthologyTriggerContext anthTriggerContext);
        Boolean getSkipLoop();

    }

    public abstract class DelegateBase implements Delegate {

        public virtual void prepareBefore() {
        }
        public virtual void prepareAfter() {
        }

        public virtual void beforeInsert(SObject o) {
        }
        public virtual void beforeUpdate(SObject old, SObject o) {
        }
        public virtual void beforeDelete(SObject o) {
        }

        public virtual void afterInsert(SObject o) {
        }
        public virtual void afterUpdate(SObject old, SObject o) {
        }
        public virtual void afterDelete(SObject o) {
        }
        public virtual void afterUndelete(SObject o) {
        }

        public virtual void finish() {
        }

        public virtual void prepareBeforeInProgress() {
        }
        public virtual void prepareAfterInProgress() {
        }

        public virtual void beforeInsertInProgress(SObject o) {
        }
        public virtual void beforeUpdateInProgress(SObject old, SObject o) {
        }
        public virtual void beforeDeleteInProgress(SObject o) {
        }

        public virtual void afterInsertInProgress(SObject o) {
        }
        public virtual void afterUpdateInProgress(SObject old, SObject o) {
        }
        public virtual void afterDeleteInProgress(SObject o) {
        }
        public virtual void afterUndeleteInProgress(SObject o) {
        }

        public virtual void finishInProgress() {
        }

        @TestVisible protected Boolean skipLoop = false;
        public Boolean getSkipLoop() {
            return skipLoop;
        }

        @TestVisible protected String name;

        @TestVisible protected AnthologyTriggerContext anthTriggerContext;
        public AnthologyTriggerContext getAnthologyTriggerContext() {
            return anthTriggerContext;
        }
        public void setAnthologyTriggerContext(AnthologyTriggerContext anthTriggerContext) {
            this.anthTriggerContext = anthTriggerContext;
        }

        public Map<String, String> getTriggerContext() {
            Map<String, String> response = new Map<String, String>();
            response.put('name', name);
            response.put('SObject', anthTriggerContext.triggerObject.getDescribe().name);
            return response;
        }

    }

    public static void execute(Delegate d) {

        switch on d.getAnthologyTriggerContext().triggerOperation {
            when BEFORE_INSERT {
                d.prepareBefore();
                if (!d.getSkipLoop()) {
                    if (d.getAnthologyTriggerContext()?.oldList != null) {
                        for (SObject o : d.getAnthologyTriggerContext().newList) {
                            d.beforeInsert(o);
                        }
                    }
                }
            }
            when BEFORE_UPDATE {
                d.prepareBefore();
                if (!d.getSkipLoop()) {
                    if (d.getAnthologyTriggerContext()?.oldList != null) {
                        for (SObject o : d.getAnthologyTriggerContext().oldList) {
                            d.beforeUpdate(o, d.getAnthologyTriggerContext().newMap.get(o.Id));
                        }
                    }
                }
            }
            when BEFORE_DELETE {
                d.prepareBefore();
                if (!d.getSkipLoop()) {
                    if (d.getAnthologyTriggerContext()?.oldList != null) {
                        for (SObject o : d.getAnthologyTriggerContext().oldList) {
                            d.beforeDelete(o);
                        }
                    }
                }
            }
            when AFTER_INSERT {
                d.prepareAfter();
                if (!d.getSkipLoop()) {
                    if (d.getAnthologyTriggerContext()?.oldList != null) {
                        for (SObject o : d.getAnthologyTriggerContext().newList) {
                            d.afterInsert(o);
                        }
                    }
                }
            }
            when AFTER_UPDATE {
                d.prepareAfter();
                if (!d.getSkipLoop()) {
                    if (d.getAnthologyTriggerContext()?.oldList != null) {
                        for (SObject o : d.getAnthologyTriggerContext().oldList) {
                            d.afterUpdate(o, d.getAnthologyTriggerContext().newMap.get(o.Id));
                        }
                    }
                }
            }
            when AFTER_DELETE {
                d.prepareAfter();
                if (!d.getSkipLoop()) {
                    if (d.getAnthologyTriggerContext()?.oldList != null) {
                        for (SObject o : d.getAnthologyTriggerContext().oldList) {
                            d.afterDelete(o);
                        }
                    }
                }
            }
            when AFTER_UNDELETE {
                d.prepareAfter();
                if (!d.getSkipLoop()) {
                    if (d.getAnthologyTriggerContext()?.oldList != null) {
                        for (SObject o : d.getAnthologyTriggerContext().oldList) {
                            d.afterUndelete(o);
                        }
                    }
                }
            }

        }
        d.finish();
    }

    public static void executeInProgress(Delegate d) {
        switch on d.getAnthologyTriggerContext().triggerOperation {
            when BEFORE_INSERT {
                d.prepareBeforeInProgress();
                if (!d.getSkipLoop()) {
                    for (SObject o : d.getAnthologyTriggerContext().newList) {
                        d.beforeInsertInProgress(o);
                    }
                }
            }
            when BEFORE_UPDATE {
                d.prepareBeforeInProgress();
                if (!d.getSkipLoop()) {
                    for (SObject o : d.getAnthologyTriggerContext().oldList) {
                        d.beforeUpdateInProgress(o, d.getAnthologyTriggerContext().newMap.get(o.Id));
                    }
                }
            }
            when BEFORE_DELETE {
                d.prepareBeforeInProgress();
                if (!d.getSkipLoop()) {
                    for (SObject o : d.getAnthologyTriggerContext().oldList) {
                        d.beforeDeleteInProgress(o);
                    }
                }
            }
            when AFTER_INSERT {
                d.prepareAfterInProgress();
                if (!d.getSkipLoop()) {
                    for (SObject o : d.getAnthologyTriggerContext().newList) {
                        d.afterInsertInProgress(o);
                    }
                }
            }
            when AFTER_UPDATE {
                d.prepareAfterInProgress();
                if (!d.getSkipLoop()) {
                    for (SObject o : d.getAnthologyTriggerContext().oldList) {
                        d.afterUpdateInProgress(o, d.getAnthologyTriggerContext().newMap.get(o.Id));
                    }
                }
            }
            when AFTER_DELETE {
                d.prepareAfterInProgress();
                if (!d.getSkipLoop()) {
                    for (SObject o : d.getAnthologyTriggerContext().oldList) {
                        d.afterDeleteInProgress(o);
                    }
                }
            }
            when AFTER_UNDELETE {
                d.prepareAfterInProgress();
                if (!d.getSkipLoop()) {
                    for (SObject o : d.getAnthologyTriggerContext().oldList) {
                        d.afterUndeleteInProgress(o);
                    }
                }
            }

        }
        d.finishInProgress();
    }
}