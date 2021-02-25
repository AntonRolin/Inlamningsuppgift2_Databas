import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 * Created by: Anton Rolin
 * Date: 24/02/2021
 * Time: 13:52
 * Project: shoeshop_klient
 * Copyright: MIT
 */
public class Client {

    private Repository repo;
    private Customer customer;
    private Order currentOrder;
    private List<Product> allProducts = new ArrayList<>();
    private Scanner scan;
    private List<Grade> allGrades;

    public Client(){
        repo = new Repository();
        userIO();
    }

    public void userIO(){
        try(Scanner scan = new Scanner(System.in)) {
            this.scan = scan;
            userLogin();
            currentOrder = new Order(customer);
            int input;

            while(true) {
                allGrades = repo.getAllGrades();
                allProducts = repo.getAllProducts();
                System.out.println("\nVad vill du göra?");
                System.out.println("1. Lägg till en produkt");
                System.out.println("2. Kolla din beställning");
                System.out.println("3. Betygsätt en produkt");
                System.out.println("4. Kolla recensioner på en produkt");
                    input = scan.nextInt();
                switch(input){
                    case 1:
                            userAddToCart(getProductsFromBrand());
                            break;
                    case 2:
                            userViewCart();
                            break;
                    case 3:
                            userReviewProduct(getProductsFromBrand());
                            break;
                    case 4:
                            userGetReviews(getProductsFromBrand());
                            break;
                    default:
                        System.out.println("Ogiltigt val\n");
                }
            }
        }catch (Exception e){
            e.printStackTrace();
            System.out.println("Error, problem med Scanner");
        }
    }

    public void userLogin(){
        String username, password;

            while(true) {
                System.out.println("Skriv in ditt användarnamn:");
                    username = scan.nextLine();
                System.out.println("Skriv in ditt lösenord:");
                    password = scan.nextLine();
                Customer c = repo.login(username, password);

                if(c != null){
                    this.customer = c;
                    System.out.println("Inloggning lyckades\n");
                    System.out.println("Välkommen "+ customer.getFirstName()+" "+customer.getLastName());
                    break;
                }
                System.out.println("\nOgiltig inloggning, försök igen");
            }
        }


    public void userAddToCart(List<Product> products){
        int newOrderID;
        int input;
        int i = 0;
        for (Product p: products) {
            i++;
            System.out.println(i+". "+p.getBrand()+", "+p.getColor()+", "+p.getSize()+"  Pris: "+p.getPrice() +"kr  Lager: "+p.getInStock());

        }
        while(true) {
            input = scan.nextInt();
            if(products.get(input-1).getInStock() < 1)
                System.out.println("Produkten är slut i lager. Välj en annan produkt.");
            else
                break;
        }
        currentOrder.addProduct(products.get(input-1));
        newOrderID = repo.addToCart(customer.getId(), products.get(input-1).getId(), currentOrder.getId());
        this.currentOrder.setId(newOrderID);
    }


    public void userReviewProduct(List<Product> products){
        int input;
        int i = 0;
        Product selectedProduct;
        Grade selectedGrade;
        String comment;
        for (Product p: products) {
            i++;
            System.out.println(i+". "+p.getBrand()+", "+p.getColor()+", "+p.getSize()+"  Pris: "+p.getPrice() +"kr");

        }
        input = scan.nextInt();
        selectedProduct = products.get(input-1);
        i = 0;
        for (Grade g: allGrades) {
            i++;
            System.out.println(i+". "+g.getDescription());
        }
        input = scan.nextInt();
        scan.nextLine();
        selectedGrade = allGrades.get(input-1);
        System.out.println("Skriv en kommentar(max 100 tecken): ");
        comment = scan.nextLine();
        repo.rateProduct(customer.getId(), selectedProduct.getId(), selectedGrade.getId(), comment);
    }

    public void userGetReviews(List<Product> products){
        int input;
        int i = 0;
        Product selectedProduct;
        int averageRating;
        List<String> comments;
        for (Product p: products) {
            i++;
            System.out.println(i+". "+p.getBrand()+", "+p.getColor()+", "+p.getSize()+"  Pris: "+p.getPrice() +"kr");

        }
        input = scan.nextInt();
        selectedProduct = products.get(input-1);
        averageRating = repo.getProductAverageRating(selectedProduct.getId());
        System.out.println("Average rating: "+averageRating+"\n");

        comments = repo.getProductComments(selectedProduct.getId());
        i = 0;
        for (String s: comments) {
            if(!s.isBlank()) {
                i++;
                System.out.println(i + ". " + s);
            }
        }
        System.out.println("\nTryck på ENTER för att gå tillbaka");
        scan.nextLine();
        scan.nextLine();
    }

    private List<Product> getProductsFromBrand(){
        List<Product> tempList = new ArrayList<>();
        List<String> brandList = getAllBrands();
        scan.nextLine();

            System.out.println("Vilket märke?");
            System.out.println(brandList.toString());
                String input = scan.nextLine();
            for (Product p: allProducts) {
                if(p.getBrand().equalsIgnoreCase(input))
                    tempList.add(p);
            }
            return tempList;
    }

    private List<String> getAllBrands(){
        List<String> tempList = new ArrayList<>();
        for (Product p: allProducts) {
            if(!tempList.contains(p.getBrand()))
                tempList.add(p.getBrand());
        }
        return tempList;
    }

    public void userViewCart(){
        List<Product> products = currentOrder.getProducts();
        scan.nextLine();

        if(products == null){
            System.out.println("Din varukorg är tom");
        }
        else {
            for (int i = 0; i < products.size(); i++) {
                System.out.println((i + 1) + ". " + products.get(i).getBrand() + ", " + products.get(i).getColor()
                        + ", " + products.get(i).getSize() + "  Pris: " + products.get(i).getPrice());
            }
        }
        System.out.println("\nTryck på ENTER för att gå tillbaka");
        scan.nextLine();
    }
}
