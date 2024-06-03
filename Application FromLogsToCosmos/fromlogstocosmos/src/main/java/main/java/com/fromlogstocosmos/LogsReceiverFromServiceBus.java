package  main.java.com.fromlogstocosmos;

import java.util.Map;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusErrorContext;
import com.azure.messaging.servicebus.ServiceBusProcessorClient;
import com.azure.messaging.servicebus.ServiceBusReceivedMessage;
import com.azure.messaging.servicebus.ServiceBusReceivedMessageContext;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;

@Configuration(proxyBeanMethods = false)
public class LogsReceiverFromServiceBus {

    private String sAzureKeyVaultURL;
    private String sServiceBusEndPointReceiver;
    private String sServiceBusQueueNameReceiver;
    private ManagedIdentityCredential credential;

    private ManagedIdentityCredential getCredential() {
        System.out.printf(" LogsReceiverFromServiceBus.getCredential: " + this.credential.getClientId().toString() + "\n");
        return this.credential;
    }
    private void setCredential(ManagedIdentityCredential credential) {
        System.out.printf(" LogsReceiverFromServiceBus.setCredential: " + credential.getClientId().toString() + "\n");
        this.credential = credential;
    }

    public LogsReceiverFromServiceBus() {
        this.setCredential(new ManagedIdentityCredentialBuilder().build());

        System.out.printf(" LogsReceiverFromServiceBus.constructor - Retriveing information from key-vault. \n");

        try {
            Map<String, String> env = System.getenv();
            this.setAzureKeyVaultURL(env.get("AZURE_KEYVAULT_URL"));

            SecretClient secretClient = new SecretClientBuilder()
                .vaultUrl(this.getAzureKeyVaultURL())
                .credential(this.getCredential())
                .buildClient();

            this.setServiceBusEndPointReceiver(secretClient.getSecret("AzureServicesLogsEndpoint").getValue() + ".servicebus.windows.net");
            this.setServiceBusQueueNameReceiver(secretClient.getSecret("AzureServicebusLogsQueue").getValue());
        } catch (Exception e) {
            System.out.printf(" LogsReceiverFromServiceBus.constructor - Error getting environment variables %s", e.getMessage(), "\n");
            throw new RuntimeException(e);
        }
    }

    private String getAzureKeyVaultURL() {
		return this.sAzureKeyVaultURL;
	}
    private void setAzureKeyVaultURL(String sAzureKeyVaultURL) {
		this.sAzureKeyVaultURL = sAzureKeyVaultURL;
	}

    private String getServiceBusEndPointReceiver() {
		return this.sServiceBusEndPointReceiver;
	}
    private void setServiceBusEndPointReceiver(String sServiceBusEndPointReceiver) {
		this.sServiceBusEndPointReceiver = sServiceBusEndPointReceiver;
	}

    private String getServiceBusQueueNameReceiver() {
		return this.sServiceBusQueueNameReceiver;
	}
    private void setServiceBusQueueNameReceiver(String sServiceBusQueueNameReceiver) {
		this.sServiceBusQueueNameReceiver = sServiceBusQueueNameReceiver;
	}

    @Bean
    ServiceBusClientBuilder serviceBusClientBuilder() {
        return new ServiceBusClientBuilder()
            .fullyQualifiedNamespace(this.getServiceBusEndPointReceiver())
            .credential(this.getCredential());
    }

    @Bean
    ServiceBusProcessorClient serviceBusProcessorClient(ServiceBusClientBuilder builderReceiver) {
        return builderReceiver.processor()
            .queueName(this.getServiceBusQueueNameReceiver())
            .processMessage(LogsReceiverFromServiceBus::processMessage)
            .processError(LogsReceiverFromServiceBus::processError)
            .buildProcessorClient();
    }

    private static void processMessage(ServiceBusReceivedMessageContext context) {
        ServiceBusReceivedMessage message = context.getMessage();
        System.out.printf("  LogsReceiverFromServiceBus.processMessage - Processing message. Id: %s, Sequence #: %s. Contents: %s%n", message.getMessageId(), message.getSequenceNumber(), message.getBody(), "\n");
        ProcessLog processLog = new ProcessLog();
        if (processLog.processLog(message)) {
            System.out.println("LogsReceiverFromServiceBus.processMessage  - Message processed with sucess. Received Message Id: " + message.getMessageId());
            context.complete();
        } else {
            System.out.println("LogsReceiverFromServiceBus.processMessage   - Message processed with error. Abandoing message.Message Id: " + message.getMessageId());
            context.abandon();
        }
    }

    private static void processError(ServiceBusErrorContext context) {
        System.out.printf("  LogsReceiverFromServiceBus.processError - Error when receiving messages from namespace: '%s'. Entity: '%s'%n", context.getFullyQualifiedNamespace(), context.getEntityPath(), "\n");
    }
}