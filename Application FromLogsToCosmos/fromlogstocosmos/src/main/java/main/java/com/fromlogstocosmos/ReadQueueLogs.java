package  main.java.com.fromlogstocosmos;

import java.util.concurrent.TimeUnit;

import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusProcessorClient;

public class ReadQueueLogs {
    public void run() {
        System.out.println(" ReadQueueLogs.Run - Connecting to the service bus....\n");
        LogsReceiverFromServiceBus logsReceiverFromServiceBus = new LogsReceiverFromServiceBus();
        ServiceBusClientBuilder serviceBusClientBuilder = logsReceiverFromServiceBus.serviceBusClientBuilder();
        ServiceBusProcessorClient processorClient =  logsReceiverFromServiceBus.serviceBusProcessorClient(serviceBusClientBuilder);

        boolean bContinueLoop = true;
        while (bContinueLoop) {
            System.out.println(" ReadQueueLogs.run - Starting reading queue executing processor....\n");
            try {
                processorClient.start();
                TimeUnit.SECONDS.sleep(5); // Take messagens during 15 seconds
                System.out.printf(" ReadQueueLogs.run - Stopping and closing the processor.\n");
                processorClient.close();
                System.out.printf(" ReadQueueLogs.run - Waiting 15 seconds to start reading more messages.\n");
                TimeUnit.SECONDS.sleep(30); // Wait 15 seconds to read more messages
            }
            catch (InterruptedException e) {
                bContinueLoop = false;
                System.out.println(" ReadQueueLogs.run - InterruptedException exception occurred. Process stopped.\n");
            }
            catch (Exception e) {
                bContinueLoop = false;
                System.out.println(" ReadQueueLogs.run - Exception occurred. Process stopped.\n");
            }
        }
    }
}