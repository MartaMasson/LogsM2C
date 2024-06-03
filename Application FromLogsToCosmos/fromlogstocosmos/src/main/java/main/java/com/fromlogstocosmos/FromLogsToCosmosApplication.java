package  main.java.com.fromlogstocosmos;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication
public class FromLogsToCosmosApplication {
	public static void main(String[] args)  {
		SpringApplication.run(FromLogsToCosmosApplication.class, args);
		System.out.println("FromLogsToCosmosApplication.main - Hello world.\n");
        ReadQueueLogs readQueueLogs = new ReadQueueLogs();
		readQueueLogs.run();
	}
}
