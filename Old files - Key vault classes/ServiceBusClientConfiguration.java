package main.java.com.fromlogstocosmos;

import java.util.Map;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusErrorContext;
import com.azure.messaging.servicebus.ServiceBusProcessorClient;
import com.azure.messaging.servicebus.ServiceBusReceivedMessage;
import com.azure.messaging.servicebus.ServiceBusReceivedMessageContext;
import com.azure.messaging.servicebus.ServiceBusSenderClient;

@Configuration(proxyBeanMethods = false)
public class ServiceBusClientConfiguration {

    private String SERVICE_BUS_FQDN;
    private String QUEUE_NAME;

    public ServiceBusClientConfiguration() {
        Map<String, String> env = System.getenv();
        SERVICE_BUS_FQDN = env.get("AZURE_SERVICEBUS_RECEIVER_ENDPOINT");
        //QUEUE_NAME = env.get("AZURE_SERVICEBUS_RECEIVER_QUEUE");
        QUEUE_NAME = "sbqueuelogs";
    }

    @Bean
    ServiceBusClientBuilder serviceBusClientBuilder() {
        return new ServiceBusClientBuilder()
            .fullyQualifiedNamespace(SERVICE_BUS_FQDN)
            .credential(new DefaultAzureCredentialBuilder().build());
    }

    @Bean
    ServiceBusSenderClient serviceBusSenderClient(ServiceBusClientBuilder builder) {
        return builder
            .sender()
            .queueName(QUEUE_NAME)
            .buildClient();
    }

    @Bean
    ServiceBusProcessorClient serviceBusProcessorClient(ServiceBusClientBuilder builder) {
        return builder.processor()
            .queueName(QUEUE_NAME)
            .processMessage(ServiceBusClientConfiguration::processMessage)
            .processError(ServiceBusClientConfiguration::processError)
            .buildProcessorClient();
    }

    private static void processMessage(ServiceBusReceivedMessageContext context) {
        ServiceBusReceivedMessage message = context.getMessage();
        System.out.printf("ServiceBusClientConfiguration.processMessage - Processing message. Id: %s, Sequence #: %s. Contents: %s%n", message.getMessageId(), message.getSequenceNumber(), message.getBody());
        context.complete();
        //context.abandon();
    }

    private static void processError(ServiceBusErrorContext context) {
        System.out.printf("ServiceBusClientConfiguration.ServiceBusClientConfiguration.processMessage - Error when receiving messages from namespace: '%s'. Entity: '%s'%n", context.getFullyQualifiedNamespace(), context.getEntityPath());
    }
}