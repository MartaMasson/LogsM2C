package  main.java.com.fromlogstocosmos;

import com.fasterxml.uuid.Generators;


// Define a class to represent a log item
public class LogItem {
    private String id;
    private String partitionKey;
    private String slogFile;
    private String sClientIP;
    private String sClientId;
    private String sClientName;
    private String sLogDate;
    private String sLogTime;
    private String sRequeString;
    private String sResponseStatusCode;
    private String sResponseSize;
    private String sUrl;
    private String sUserAgent;
    
    // Getters and setters for the properties
    public String getId() {
        return this.id;
    }
    public void setId() {
       this.id = (Generators.timeBasedGenerator().generate()).toString(); // Version 1

        //this.id = UUID.randomUUID().toString();
    }
    
    public String getPartitionKey() {
        return this.partitionKey;
    }
    public void setPartitionKey(String partitionKey) {
        this.partitionKey = partitionKey;
    }

    public String getLogFile() {
        return this.slogFile;
    }
    public void setLogFile(String slogFile) {
        this.slogFile = slogFile;
    }

    public String getClientIP() {
        return this.sClientIP;
    }
    public void setClientIP(String sClientIP) {
        this.sClientIP = sClientIP;
    }

    public String getClientId() {
        return this.sClientId;
    }
    public void setClientId(String sClientId) {
        this.sClientId = sClientId;
    }

    public String getClientName() {
        return this.sClientName;
    }
    public void setClientName(String sClientName) {
        this.sClientName = sClientName;
    }

    public String getLogDate() {
        return this.sLogDate;
    }
    public void setLogDate(String sLogDate) {
        this.sLogDate = sLogDate;
    }

    public String getLogTime() {
        return this.sLogTime;
    }
    public void setLogTime(String sLogTime) {
        this.sLogTime = sLogTime;
    }

    public String getRequeString() {
        return this.sRequeString;
    }
    public void setRequeString(String sRequeString) {
        this.sRequeString = sRequeString;
    }

    public String getResponseStatusCode() {
        return this.sResponseStatusCode;
    }
    public void setResponseStatusCode(String sResponseStatusCode) {
        this.sResponseStatusCode = sResponseStatusCode;
    }

    public String getResponseSize() {
        return this.sResponseSize;
    }
    public void setResponseSize(String sResponseSize) {
        this.sResponseSize = sResponseSize;
    }

    public String getUrl() {
        return this.sUrl;
    }
    public void setUrl(String sUrl) {
        this.sUrl = sUrl;
    }

    public String getUserAgent() {
        return this.sUserAgent;
    }
    public void setUserAgent(String sUserAgent) {
        this.sUserAgent = sUserAgent;
    }
}
