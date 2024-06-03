package  main.java.com.fromfilestologs;

import java.util.concurrent.TimeUnit;

import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusProcessorClient;

public class ReadQueueFiles {
    public void run() {
        System.out.println(" ReadQueueFiles.Run - Connecting to the service bus....\n");
        FilesReceiverFromServiceBus filesReceiverFromServiceBus = new FilesReceiverFromServiceBus();
        //filesReceiverFromServiceBus.serviceBusClientBuilder();
        ServiceBusClientBuilder serviceBusClientBuilder = filesReceiverFromServiceBus.serviceBusClientBuilder();
        ServiceBusProcessorClient processorClient =  filesReceiverFromServiceBus.serviceBusProcessorClient(serviceBusClientBuilder);

        boolean bContinueLoop = true;
        while (bContinueLoop) {
            System.out.println(" ReadQueueFiles.run - Starting reading queue executing processor....\n");
            try {
                processorClient.start();
                TimeUnit.SECONDS.sleep(5); // Take messagens during 15 seconds
                System.out.printf(" ReadQueueFiles.run - Stopping and closing the processor.\n");
                processorClient.close();
                System.out.printf(" ReadQueueFiles.run - Waiting 15 seconds to start reading more messages.\n");
                TimeUnit.SECONDS.sleep(5); // Wait 15 seconds to read more messages
            }
            catch (InterruptedException e) {
                bContinueLoop = false;
                System.out.println(" ReadQueueFiles.run - InterruptedException exception occurred. Process stopped.\n");
            }
            catch (Exception e) {
                bContinueLoop = false;
                System.out.println(" ReadQueueFiles.run - Exception occurred. Process stopped.\n");
            }
        }
    }
}