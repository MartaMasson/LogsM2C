package main.java.com.fromfilestologs;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
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
public class FilesReceiverFromServiceBus {

    private String sAzureKeyVaultURL;
    private String sServiceBusEndPointReceiver;
    private String sServiceBusQueueNameReceiver;
    private ManagedIdentityCredential credential;

    private ManagedIdentityCredential getCredential() {
        System.out.printf(" FilesReceiverFromServiceBus.getCredential: " + this.credential.getClientId().toString() + "\n");
        return this.credential;
    }
    private void setCredential(ManagedIdentityCredential credential) {
        System.out.printf(" FilesReceiverFromServiceBus.setCredential: " + credential.getClientId().toString() + "\n");
        this.credential = credential;
    }


    public FilesReceiverFromServiceBus() {
        this.setCredential(new ManagedIdentityCredentialBuilder().build());

        System.out.printf(" FilesReceiverFromServiceBus.constructor - Retriveing information from key-vault. \n");

        try {
            Map<String, String> env = System.getenv();

            this.setAzureKeyVaultURL(env.get("AZURE_KEYVAULT_URL"));

            SecretClient secretClient = new SecretClientBuilder()
                .vaultUrl(this.getAzureKeyVaultURL())
                .credential(this.getCredential())
                .buildClient();

            this.setServiceBusEndPointReceiver(secretClient.getSecret("AzureServicesFilesEndpoint").getValue() + ".servicebus.windows.net");
            this.setServiceBusQueueNameReceiver(secretClient.getSecret("AzureServicebusFilesQueue").getValue());

        } catch (Exception e) {
            System.out.printf(" FilesReceiverFromServiceBus.constructor - Error getting environment variables %s", e.getMessage(), "\n");
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
    @Autowired
    @Qualifier("Receiver")
    ServiceBusClientBuilder serviceBusClientBuilder() {
        return new ServiceBusClientBuilder()
            .fullyQualifiedNamespace(this.getServiceBusEndPointReceiver())
            .credential(this.getCredential());
    }

    @Bean
    ServiceBusProcessorClient serviceBusProcessorClient(@Qualifier("Receiver") ServiceBusClientBuilder builderReceiver) {
        return builderReceiver.processor()
            .queueName(this.getServiceBusQueueNameReceiver())
            .processMessage(FilesReceiverFromServiceBus::processMessage)
            .processError(FilesReceiverFromServiceBus::processError)
            .buildProcessorClient();
    }

    private static void processMessage(ServiceBusReceivedMessageContext context) {
        ServiceBusReceivedMessage message = context.getMessage();
        System.out.printf("  FilesReceiverFromServiceBus.processMessage - Processing message. Id: %s, Sequence #: %s. Contents: %s%n", message.getMessageId(), message.getSequenceNumber(), message.getBody(), "\n");
        ProcessFile processFile = new ProcessFile();
        if (processFile.getLogsFromFiles(message)) {
            System.out.println("Run - Message processed with sucess. Received Message Id: " + message.getMessageId());
            context.complete();
        } else {
            System.out.println("Run - Message processed with error. Abandoing message.Message Id: " + message.getMessageId());
            context.abandon();
        }
    }

    private static void processError(ServiceBusErrorContext context) {
        System.out.printf("  FilesReceiverFromServiceBus.processError - Error when receiving messages from namespace: '%s'. Entity: '%s'%n", context.getFullyQualifiedNamespace(), context.getEntityPath(), "\n");
    }
}