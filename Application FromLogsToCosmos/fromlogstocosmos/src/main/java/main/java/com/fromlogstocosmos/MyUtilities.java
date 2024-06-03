package  main.java.com.fromlogstocosmos;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.Locale;

public class MyUtilities {

	public static Date convertStrToDate(String sDateTimeString) {
		DateFormat df = new SimpleDateFormat("dd/MMM/yyyy:HH:mm:ss", Locale.ENGLISH);
		Date dConvert;
		try {
			dConvert = df.parse(sDateTimeString);
            return dConvert;
  	    } catch (ParseException e) {
		    e.printStackTrace();
		    return null;
	    }
	}

	public static String convertDateToStr(Date dDate) {
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
		String sDate = sdf.format(dDate).toString();
		return (sDate);
	}

	public static String extractTime(String sDateTimeString) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MMM/yyyy:HH:mm:ss", Locale.ENGLISH);
        LocalDateTime dateTime = LocalDateTime.parse(sDateTimeString, formatter);
        return dateTime.toLocalTime().toString();
	}

	public static String extractDate(String sDateTimeString) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MMM/yyyy:HH:mm:ss", Locale.ENGLISH);
        LocalDateTime dateTime = LocalDateTime.parse(sDateTimeString, formatter);
        return dateTime.toLocalDate().toString();
	}

}