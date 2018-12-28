
class pts // class for manipulaitng and displaying pointclouds or polyloops in 3D 
  { 
    int maxnv = 16000;                 //  max number of vertices
    pt[] G = new pt [maxnv];           // geometry table (vertices)
    char[] L = new char [maxnv];             // labels of points
    vec [] LL = new vec[ maxnv];  // displacement vectors
    Boolean loop=true;          // used to indicate closed loop 3D control polygons
    int pv =0,     // picked vertex index,
        iv=0,      //  insertion vertex index
        dv = 0,   // dancer support foot index
        nv = 0,    // number of vertices currently used in P
        pp=1; // index of picked vertex

  pts() {}
  pts declare() 
    {
    for (int i=0; i<maxnv; i++) G[i]=P(); 
    for (int i=0; i<maxnv; i++) LL[i]=V(); 
    return this;
    }     // init all point objects
  pts empty() {nv=0; pv=0; return this;}                                 // resets P so that we can start adding points
  pts addPt(pt P, char c) { G[nv].setTo(P); pv=nv; L[nv]=c; nv++;  return this;}          // appends a new point at the end
  pts addPt(pt P) { G[nv].setTo(P); pv=nv; L[nv]='f'; nv++;  return this;}          // appends a new point at the end
  pts addPt(float x,float y) { G[nv].x=x; G[nv].y=y; pv=nv; nv++; return this;} // same byt from coordinates
  pts copyFrom(pts Q) {empty(); nv=Q.nv; for (int v=0; v<nv; v++) G[v]=P(Q.G[v]); return this;} // set THIS as a clone of Q

  pts resetOnCircle(int k, float r)  // sets THIS to a polyloop with k points on a circle of radius r around origin
    {
    empty(); // resert P
    pt C = P(); // center of circle
    for (int i=0; i<k; i++) addPt(R(P(C,V(0,-r,0)),2.*PI*i/k,C)); // points on z=0 plane
    pv=0; // picked vertex ID is set to 0
    return this;
    } 
  // ********* PICK AND PROJECTIONS *******  
  int SETppToIDofVertexWithClosestScreenProjectionTo(pt M)  // sets pp to the index of the vertex that projects closest to the mouse 
    {
    pp=0; 
    for (int i=1; i<nv; i++) if (d(M,ToScreen(G[i]))<=d(M,ToScreen(G[pp]))) pp=i; 
    return pp;
    }
  pts showPicked() {show(G[pv],23); return this;}
  pt closestProjectionOf(pt M)    // Returns 3D point that is the closest to the projection but also CHANGES iv !!!!
    {
    pt C = P(G[0]); float d=d(M,C);       
    for (int i=1; i<nv; i++) if (d(M,G[i])<=d) {iv=i; C=P(G[i]); d=d(M,C); }  
    for (int i=nv-1, j=0; j<nv; i=j++) { 
       pt A = G[i], B = G[j];
       if(projectsBetween(M,A,B) && disToLine(M,A,B)<d) {d=disToLine(M,A,B); iv=i; C=projectionOnLine(M,A,B);}
       } 
    return C;    
    }

  // ********* MOVE, INSERT, DELETE *******  
  pts insertPt(pt P) { // inserts new vertex after vertex with ID iv
    for(int v=nv-1; v>iv; v--) {G[v+1].setTo(G[v]);  L[v+1]=L[v];}
     iv++; 
     G[iv].setTo(P);
     L[iv]='f';
     nv++; // increments vertex count
     return this;
     }
  pts insertClosestProjection(pt M) {  
    pt P = closestProjectionOf(M); // also sets iv
    insertPt(P);
    return this;
    }
  pts deletePicked() 
    {
    for(int i=pv; i<nv; i++) 
      {
      G[i].setTo(G[i+1]); 
      L[i]=L[i+1]; 
      }
    pv=max(0,pv-1); 
    nv--;  
    return this;
    }
  pts setPt(pt P, int i) { G[i].setTo(P); return this;}
  
  pts drawBalls(float r) {for (int v=0; v<nv; v++) show(G[v],r); return this;}
  pts showPicked(float r) {show(G[pv],r); return this;}
  pts drawClosedCurve(float r) 
    {
    //fill(dgreen);
    //for (int v=0; v<nv; v++) show(G[v],r*3);    
    fill(magenta);
    for (int v=0; v<nv-1; v++) stub(G[v],V(G[v],G[v+1]),r,r);  
    stub(G[nv-1],V(G[nv-1],G[0]),r,r);
    pushMatrix(); //translate(0,0,1); 
    scale(1,1,0.03);  
    fill(grey);
    for (int v=0; v<nv; v++) show(G[v],r*3);    
    for (int v=0; v<nv-1; v++) stub(G[v],V(G[v],G[v+1]),r,r);  
    stub(G[nv-1],V(G[nv-1],G[0]),r,r);
    popMatrix();
    return this;
    }
  pts set_pv_to_pp() {pv=pp; return this;}
  pts movePicked(vec V) { G[pv].add(V); return this;}      // moves selected point (index p) by amount mouse moved recently
  pts setPickedTo(pt Q) { G[pv].setTo(Q); return this;}      // moves selected point (index p) by amount mouse moved recently
  pts moveAll(vec V) {for (int i=0; i<nv; i++) G[i].add(V); return this;};   
  pt Picked() {return G[pv];} 
  pt Pt(int i) {if(0<=i && i<nv) return G[i]; else return G[0];} 

  // ********* I/O FILE *******  
 void savePts(String fn) 
    {
    String [] inppts = new String [nv+1];
    int s=0;
    inppts[s++]=str(nv);
    for (int i=0; i<nv; i++) {inppts[s++]=str(G[i].x)+","+str(G[i].y)+","+str(G[i].z)+","+L[i];}
    saveStrings(fn,inppts);
    };
  
  void loadPts(String fn) 
    {
    println("loading: "+fn); 
    String [] ss = loadStrings(fn);
    String subpts;
    int s=0;   int comma, comma1, comma2;   float x, y;   int a, b, c;
    nv = int(ss[s++]); print("nv="+nv);
    for(int k=0; k<nv; k++) 
      {
      int i=k+s; 
      //float [] xy = float(split(ss[i],",")); 
      String [] SS = split(ss[i],","); 
      G[k].setTo(float(SS[0]),float(SS[1]),float(SS[2]));
      L[k]=SS[3].charAt(0);
      }
    pv=0;
    };
 
  // Dancer
  void setPicekdLabel(char c) {L[pp]=c;}
  


  void setFifo() 
    {
    _LookAtPt.reset(G[dv],60);
    }              


  void next() {dv=n(dv);}
  int n(int v) {return (v+1)%nv;}
  int p(int v) {if(v==0) return nv-1; else return v-1;}
  int n(int v, int nv) {return (v+1)%nv;}
  int p(int v, int nv) {if(v==0) return nv-1; else return v-1;}  
  
  pts subdivideDemoInto(pts Q) 
    {
    Q.empty();
    for(int i=0; i<nv; i++)
      {
      Q.addPt(P(G[i])); 
      Q.addPt(P(G[i],G[n(i)])); 
      //...
      }
    return this;
    }  
  
  pts subdivideQuinticInto(pts R)
    {
     pts Q = new pts();
     Q.copyFrom(R);
     R.empty();
     for (int i=0; i<Q.nv; i++) {
       R.addPt(B(Q.G[p(i, nv)], Q.G[i], Q.G[n(i, nv)], s));
       R.addPt(F(Q.G[p(i, nv)], Q.G[i], Q.G[n(i, nv)], Q.G[n(n(i, nv), nv)], s));
     }
     return this;
    }
  
   int r = 0;
   int l = 0;
    boolean moveLeft = true;
    boolean moveRight = false;
  void displaySkater() 
      {
      if(showCurve) {fill(yellow); for (int j=0; j<nv; j++) caplet(G[j],6,G[n(j)],6); }
      pt[] B = new pt [nv];           // geometry table (vertices)
      for (int j=0; j<nv; j++) {
        vec accel = A(V(G[p(j)],G[j]), level, V(G[j],G[n(j)]));
        pt tem = P(G[j]);
        tem = P(tem, -scal, accel);
        tem.z = 0;
        B[j] = tem;
      }
      if(showPath) {fill(lime); for (int j=0; j<nv; j++) caplet(B[j],6,B[n(j)],6);} 
      if(showKeys) {fill(cyan); for (int j=0; j<nv; j+=4) arrow(B[j],G[j],3);}
      
      if (animating) {
         f=n(f);
      }
      if(showSkater) 
        {
        int stride = 10;
        if (abs(r - l) >= stride && r > l) {
          moveLeft = true;
          moveRight = false;
        } else if (abs(r - l) >= stride && l > r){
          moveLeft = false;
          moveRight = true;
        }
        //if (abs(l - r) >= stride && l > r) {
        //  moveRight = true;
        //} else {
        //  moveRight = false;
        //}
        if (moveRight) {
          r++;
        } else {
          r--;
        }
        if (moveLeft) {
          l++;
        } else {
          l--;
        }
        int n = (f-r) %nv;
        if (n<0) {
          n = n + nv;
        }
        int n2 = (f-l) %nv;
        if (n2<0) {
          n2 = n2 +nv;
        }
        
      

        //kneeless(B);
        //kneefull1(B, n, n2);
        kneefull2(B, n, n2);
        //kneefull2(B);
          
  //pt A=P.Pt(0); fill(red); show(A,20);
  //pt B=P.Pt(1); fill(green); show(B, 30);
  //pt C=P.Pt(2); fill(blue); show(C, 40);
  //pt D=P.Pt(3); fill(cyan); show(D, 20);


  //fill(orange); caplet(A,20,B,30); //lower
  //fill(yellow); caplet(C,40,B,30); //upper
  
  //pt M = P(A,C); fill(blue); show(A,10);
  
  //vec V = cross(V(A,D),V(A,C));
  //fill(red); arrow(M,300,U(V),10); //U(V) is normalized V
       }
      else {fill(red); arrow(B[f],G[f],20);} //
      }
      
      void kneeless(pt[] B)              
      {
        vec V = cross(V(B[n(f)],B[p(f)]),V(B[f],G[f]));
        //fill(red); arrow(B[f],300,U(V),10); //U(V) is normalized V
        
        pt foot1=B[f]; fill(red); show(foot1.add(100,U(V)),20); //foot
        pt hip1=G[f]; fill(blue); show(hip1, 30); //hip
        fill(orange); caplet(foot1,10,hip1,30); //leg
        
        pt foot2=B[f]; fill(red); show(foot2.add(-200,U(V)), 20); //foot
        pt hip2=G[f]; fill(blue); show(hip2, 30); //hip
        fill(orange); caplet(foot2,10,hip2,30); //leg
        
        //g(f) where body is
        //b(f) center of foot
        //l = left
        //r = right
        //i = where body is = f
        //30 steps back and forth
      }
      
      void kneefull1(pt[] B, int left, int right)
      {
         vec Ftl = cross(V(B[n(left)],B[p(left)]),V(B[left],G[left]));
         //pt foot1=P(B[f]); foot1.z = 0; fill(magenta); show(foot1.add(100,U(P)),20); //foot
         pt foot1 = P(B[left],100,U(Ftl)); foot1.z = 0; //fill(magenta); show(foot1,15);
         pt hip1 = P(G[f],20,U(Ftl)); fill(blue); show(hip1,35); //hip
         pt mid = P(foot1,hip1); //fill(red); show(mid, 10); // midpoint between foot and hip
         
         
         pt D=B[n(f)]; fill(cyan); show(D,20); //forward direction

         vec V = U(cross(V(foot1,hip1),V(foot1,D))); //cross product of forward direction and foot-hip vec
         //arrow(mid, 100, U(V), 10);
         
         vec W = U(cross(V(foot1,hip1), V)); // unit of cross of V and foot-hip
         //fill(red); arrow(mid, 100, U(W), 10);
         
         float m = d(mid, hip1);
         float d = sqrt(pow(120,2) - pow(m,2)); //knee distance from M  //d(P,Q) returns distance from P to Q  //compute d from e, knee, hip
         pt knee = P(mid,d,V); fill(green); show(knee,25);  //green knee start at M, go d units in direction of W
        
         fill(blue); caplet(foot1,15,knee,25); //lower leg
         fill(blue); caplet(hip1,35,knee,25); //upper leg
         
         foot1.z = 0;
         
         

        
        //pt foot2=B[f]; fill(red); show(foot2.add(-200,U(V)), 20); //foot
        //pt knee2=B[f]; fill(red); show(foot1.add(100,U(V)),20); //foot
        //pt hip2=G[f]; fill(blue); show(hip2, 30); //hip
        //fill(orange); caplet(foot2,10,hip2,30); //leg
               
      }
      
      void kneefull2(pt[] B, int left, int right)
      {
         vec Ftr = cross(V(B[n(right)],B[p(right)]),V(B[right],G[right]));
         vec Ftl = cross(V(B[n(left)],B[p(left)]),V(B[left],G[left]));
         vec Ft = cross(V(B[n(f)],B[p(f)]),V(B[f],G[f]));
         pt foothelper2 = P(B[f],-100,U(Ft)); //foot2.z = 0; fill(magenta); show(foot2,15);
         pt foothelper1 = P(B[f],100,U(Ft)); //foot1.z = 0; //fill(magenta); show(foot1,20);
         pt foot1 = P(B[left],60,U(Ftr));  fill(green); show(foot1,20);
         pt foot2 = P(B[right],-60,U(Ftl));  fill(green); show(foot2,20);
         
         pt hip2 = P(G[f],-20,U(Ftl)); fill(blue); show(hip2,35); //hip
         pt hip1 = P(G[f],20,U(Ftr)); fill(blue); show(hip1,40); //hip
         pt arm1 = P(G[f+2],70,U(Ftr));
         pt arm2 = P(G[f+2],-70,U(Ftl));
         pt elbow1 = P(G[f+2],72,U(Ftr)); fill(green); show(elbow1,19);
         pt elbow2 = P(G[f+2],-72,U(Ftl)); fill(green); show(elbow2,19);
         
         pt mid2 = P(foot2,hip2); //fill(red); show(mid, 10); // midpoint between foot and hip
         pt mid = P(foot1,hip1); //fill(red); show(mid, 10); // midpoint between foot and hip
         pt midhips = P(hip1,hip2); //fill(red); show(midhips, 10);
         pt midarms1 = P(elbow1,arm1);
         pt midarms2 = P(elbow2,arm2);
         
         
         
         pt D1=B[n(f)]; //fill(cyan); show(D1,20); //fwd dir
         pt D2=B[n(f)]; //fill(cyan); show(D2,20); //fwd dir
         pt D3=B[right]; //fill(cyan); show(D2,20); //fwd dir
         pt D4=B[left]; //fill(cyan); show(D2,20); //fwd dir

         //pt D2=G[n(f)]; fill(orange); show(D2,20);

         vec V = U(cross(V(foothelper2,D2),V(foothelper2,hip2))); 
         vec V1 = U(cross(V(foothelper1,D1),V(foothelper1,hip1))); 
         vec Vcomb = U(cross(V1,V));
                  
         vec W = U(cross(V(foothelper2,hip2), V));
         vec W3 = U(cross(V(foothelper1,hip1), V1));
         vec W2 = U(cross(V(foothelper2,hip2), Vcomb));
         vec W1 = U(cross(V(foothelper1,hip1), Vcomb)); 
         vec Wcomb = U(cross(W1,W2));
         vec Varm1 = U(cross(V(elbow1,arm1),V(elbow1,D3)));
         vec Varm2 = U(cross(V(elbow2,D4),V(elbow2,arm2)));

         
         
         float m = d(mid2, hip2);
         float mbody = d(midhips, hip2);
         float marms = d(midarms1, arm1);
         float d = sqrt(pow(120,2) - pow(m,2)); 
         float d2 = sqrt(pow(90,2) - pow(mbody,2)); 
         float d4 = sqrt(pow(80,2) - pow(marms,2)); 
         pt knee1 = P(mid,d,V); fill(green); show(knee1,25); 
         pt knee2 = P(mid2,d,V); fill(green); show(knee2,25); 
         pt hand1 = P(midarms1,d4,Varm1); fill(green); show(hand1,15);
         pt hand2 = P(midarms2,d4,Varm2); fill(green); show(hand2,15);
         pt torso = P(midhips,d2,Wcomb); fill(blue); show(torso,50);
         pt midtorso = P(torso); //fill(yellow); show(midtorso,40);
         float d3 = sqrt(pow(120,2) - pow(mbody,2)); //change mbody to mtorso?
         pt neck = P(midtorso,60,Wcomb); 
         pt midneck = P(neck); //fill(yellow); show(midneck,40);
         pt necklace = P(torso,neck); fill(green); show(necklace,30);
         pt hat2 = P(necklace,d2,Wcomb); fill(green); show(hat2,30);
         pt balloon1 = P(1.5,necklace); fill(red); show(balloon1,40);
         pt balloon2 = P(hand2,balloon1); fill(white); caplet(hand2,5,balloon2,5);
         //pt necklace2 = P(torso,50,neck); fill(red); show(necklace2,30);
         pt head = P(midneck,35,Wcomb); fill(blue); show(head,40);
         pt midhead = P(head);
         pt hat = P(midhead,40,Wcomb); fill(green); caplet(midhead,30,hat,40);
         
         

         //pt arm1 = P(G[f],20,U(Ft)); // how to make a dress

        
         fill(blue); caplet(foot2,15,knee2,25); //lower leg
         fill(blue); caplet(hip2,35,knee2,25); //upper leg
         fill(blue); caplet(foot1,15,knee1,25); //lower leg
         fill(blue); caplet(hip1,35,knee1,25); //upper leg
         fill(blue); caplet(midhips,40,torso,50);
         fill(blue); caplet(midtorso,30,neck,20);
         fill(blue); caplet(midtorso,35,arm1,20);
         fill(blue); caplet(midtorso,35,arm2,20);
         fill(blue); caplet(elbow1,20,hand1,15);
         fill(blue); caplet(elbow2,20,hand2,15);
         fill(yellow); caplet(midtorso,30,arm2,10);
         fill(white); caplet(hand2,5,balloon1,5);
         //fill(yellow); caplet(necklace,20,arm2,40);
         
         
        
        //pt foot2=B[f]; fill(red); show(foot2.add(-200,U(V)), 20); //foot
        //pt knee2=B[f]; fill(red); show(foot1.add(100,U(V)),20); //foot
        //pt hip2=G[f]; fill(blue); show(hip2, 30); //hip
        //fill(orange); caplet(foot2,10,hip2,30); //leg
               
      }

      



        

} // end of pts class
