package turingpatterns;

import processing.core.PApplet;

import static processing.core.PApplet.*;

public class Colours {

   private final PApplet applet;

   public Colours(PApplet applet) {
      this.applet = applet;
   }


   public RGBValue createRGB(float r, float g, float b, float a) {
      RGBValue result = new RGBValue();
      result.r = map(r, 0, 255, 0, 1);
      result.g = map(g, 0, 255, 0, 1);
      result.b = map(b, 0, 255, 0, 1);
      result.a = map(a, 0, 255, 0, 1);
      return result;
   }

   public class RGBValue {
      float r;
      float g;
      float b;
      float a;

      public HSVValue toHSV() {
         HSVValue result = new HSVValue();
         result.a = a;

         float minV = Math.min(r, Math.min(g, b));
         float maxV = Math.max(r, Math.max(g, b));
         result.v = maxV;
         float delta = maxV - minV;

         if (maxV != 0) {
            result.s = delta / maxV;
         } else {
            result.hu = -1;
            result.s = 0;
            result.v = -1;
            return result;
         }

         if (delta == 0) {
            result.hu = 0;
         } else if (r == maxV) {
            result.hu = (g - b) / delta;
         } else if (g == maxV) {
            result.hu = 2 + (b - r) / delta;
         } else {
            result.hu = 4 + (r - g) / delta;
         }

         result.hu *= 60;
         if (result.hu < 0) {
            result.hu += 360;
         }

         return result;
      }

      public int toColor() {
         return applet.color(
             map(r, 0, 1, 0, 255),
             map(g, 0, 1, 0, 255),
             map(b, 0, 1, 0, 255),
             255
         );
      }

      public String toString() {
         return "RGB[" + r + ", " + g + ", " + b + "]";
      }
   }

   public class HSVValue {
      public float hu;
      public float s;
      public float v;
      public float a;

      public RGBValue toRGB() {
         RGBValue result = new RGBValue();
         if (s == 0) {
            result.r = v;
            result.g = v;
            result.b = v;
            return result;
         }

         float h = hu / 60;
         int i = (int) Math.floor(h);
         float f = h - i;
         float p = v * (1 - s);
         float q = v * (1 - s * f);
         float t = v * (1 - s * (1 - f));
         switch (i) {
            case 0:
               result.r = v;
               result.g = t;
               result.b = p;
               break;
            case 1:
               result.r = q;
               result.g = v;
               result.b = p;
               break;
            case 2:
               result.r = p;
               result.g = v;
               result.b = t;
               break;
            case 3:
               result.r = p;
               result.g = q;
               result.b = v;
               break;
            case 4:
               result.r = t;
               result.g = p;
               result.b = v;
               break;
            // case 5:
            default:
               result.r = v;
               result.g = p;
               result.b = q;
               break;
         }

         return result;
      }

      public String toString() {
         return "HSV[" + hu + ", " + s + ", " + v + "]";
      }
   }
}
