import behaviorism.utils.Utils;
import java.awt.Point;
import java.awt.event.KeyEvent;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Collection;
import java.util.Collections;

import java.util.Properties;

public class HoweMaker {

  static boolean OUTPUT_JSON = true;

  public Word lastSelected = null;

  public static void main(String[] args) {

    int NUM_LINES = 2000000;

    //1. LOAD STUFF IN AND DO INITIAL ANALYSIS
    Parser.loadInPoems(new File("EmilyDickinsonPoems.txt"), NUM_LINES);
    Parser.rankWords();

    makeHowe();
    
  }

  
	public static <T> List<T> randomElements(Collection<T> collection, int howMany) {
		if (collection.size() < howMany) {
			System.err.println("ERROR : you are requesting too many elements from this list!");
			return null;
		}

		List<T> list = new ArrayList<T>(collection);

		Collections.shuffle(list);

		List<T> returnList = new ArrayList<T>();
		for (int i = 0; i < howMany; i++) {
			returnList.add(list.get(i));
		}
		return returnList;
	}


  private static void makeHowe()
  {
      System.out.print("[\n");

      List<Line> lines = HoweMaker.randomElements(Parser.lines, Utils.randomInt(8,18));

      for (int i = 0; i < lines.size(); i++) {
        Line l = lines.get(i);
        String s = l.text;
        s = s.replaceAll("\"", "\\\\\"");

        System.out.print("\t\""+s+"\"");
      
        if (i < lines.size() - 1) {
          System.out.print(",");
        }
   
        System.out.print("\n");
       
      }

      System.out.print("]\n");

  }



}
