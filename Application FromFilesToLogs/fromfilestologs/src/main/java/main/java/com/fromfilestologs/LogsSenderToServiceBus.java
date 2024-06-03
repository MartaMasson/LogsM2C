package main.java.com.fromfilestologs;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;

@Configuration(proxyBeanMethods = false)
public class LogsSenderToServiceBus {
    private String sAzureKeyVaultURL;
    private String sServiceBusEndPointSender;
    private String sServiceBusQueueNameSender;
    private ManagedIdentityCredential credential;

    private ManagedIdentityCredential getCredential() {
        System.out.printf(" LogsSenderToServiceBus.getCredential: " + this.credential.getClientId().toString() + "\n");
        return this.credential;
    }
    private void setCredential(ManagedIdentityCredential credential) {
        System.out.printf(" LogsSenderToServiceBus.setCredential: " + credential.getClientId().toString() + "\n");
        this.credential = credential;
    }

    public LogsSenderToServiceBus() {
        this.setCredential(new ManagedIdentityCredentialBuilder().build());

        System.out.printf(" LogsSenderToServiceBus.constructor - Retriveing information from key-vault. \n");

        try {
            Map<String, String> env = System.getenv();

            this.setAzureKeyVaultURL(env.get("AZURE_KEYVAULT_URL"));

            SecretClient secretClient = new SecretClientBuilder()
                .vaultUrl(this.getAzureKeyVaultURL())
                .credential(this.getCredential())
                .buildClient();

            this.setServiceBusEndPointSender(secretClient.getSecret("AzureServicesLogsEndpoint").getValue()+ ".servicebus.windows.net");
            this.setServiceBusQueueNameSender(secretClient.getSecret("AzureServicebusLogsQueue").getValue());
        } catch (Exception e) {
            System.out.printf(" LogsSenderToServiceBus.constructor - Error getting keyvault variables %s", e.getMessage(), "\n");
            throw new RuntimeException(e);
        }
    }

    private String getAzureKeyVaultURL() {
		return this.sAzureKeyVaultURL;
	}
    private void setAzureKeyVaultURL(String sAzureKeyVaultURL) {
		this.sAzureKeyVaultURL = sAzureKeyVaultURL;
	}

    private String getServiceBusEndPointSender() {
		return this.sServiceBusEndPointSender;
	}
    private void setServiceBusEndPointSender(String sServiceBusEndPointSender) {
		this.sServiceBusEndPointSender = sServiceBusEndPointSender;
	}

    private String getServiceBusQueueNameSender() {
		return this.sServiceBusQueueNameSender;
	}
    private void setServiceBusQueueNameSender(String sServiceBusQueueNameSender) {
		this.sServiceBusQueueNameSender = sServiceBusQueueNameSender;
	}

    @Bean
    @Autowired
    @Qualifier("Sender")
    ServiceBusClientBuilder serviceBusClientSenderBuilder() {
        return new ServiceBusClientBuilder()
            .fullyQualifiedNamespace(this.getServiceBusEndPointSender())
            .credential(this.getCredential());
    }

    @Bean
    ServiceBusSenderClient serviceBusSenderClient(@Qualifier("Sender") ServiceBusClientBuilder builderSender) {
        return builderSender
            .sender()
            .queueName(this.getServiceBusQueueNameSender())
            .buildClient();
    }
}