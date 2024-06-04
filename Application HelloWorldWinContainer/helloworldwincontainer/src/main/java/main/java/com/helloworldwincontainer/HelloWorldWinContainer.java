package  main.java.com.helloworldwincontainer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication
public class HelloWorldWinContainer {
	public static void main(String[] args)  {
		SpringApplication.run(HelloWorldWinContainer.class, args);
		System.out.println("HelloWorldWinContainer.main - Hello world running on a Windows Container.\n");
		while(true) {
			System.out.println("HelloWorldWinContainer.main - Keep execution to follow CPU and Memory resources consumption in Prometheus.\n");

		}
	}
}
