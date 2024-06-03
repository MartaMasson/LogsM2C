package  main.java.com.fromfilestologs;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication
public class FromFilesToLogsApplication {

	public static void main(String[] args)  {
		SpringApplication.run(FromFilesToLogsApplication.class, args);
		System.out.println("FromFilesToLogsApplication.main - Hello world.\n");
        ReadQueueFiles readQueueFiles = new ReadQueueFiles();
	    readQueueFiles.run();
	}
}
