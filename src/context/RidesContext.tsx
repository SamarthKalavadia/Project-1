import React, { createContext, useContext, useState } from 'react';

export interface User {
  name: string;
  photo: string;
  phone: string;
  email: string;
  gender: 'Male' | 'Female' | 'Other';
}

export interface RideRequest {
  id: string;
  user: User;
  status: 'Pending' | 'Accepted' | 'Declined';
  timestamp: string;
}

export interface Ride {
  id: string;
  pickup: string;
  destination: string;
  departureTime: string;
  departureTimestamp: number;
  seatsTotal: number;
  seatsLeft: number;
  fareEstimate: string;
  notes: string;
  status: 'Pending' | 'Accepted' | 'Completed' | 'Cancelled';
  poster: User;
  acceptor: User | null;
  requests: RideRequest[];
  genderPreference: 'Boys only' | 'Girls only' | 'Both';
}

export interface Filters {
  pickup: string;
  destination: string;
  seats: number | null;
  timeSlot: 'all' | 'morning' | 'afternoon' | 'evening' | 'night';
}

interface RidesContextType {
  rides: Ride[];
  currentUser: User | null;
  filters: Filters;
  setFilters: React.Dispatch<React.SetStateAction<Filters>>;
  clearFilters: () => void;
  addRide: (ride: Omit<Ride, 'id' | 'status' | 'poster' | 'acceptor' | 'requests'>) => void;
  requestToJoin: (rideId: string) => void;
  acceptRequest: (rideId: string, requestId: string) => void;
  declineRequest: (rideId: string, requestId: string) => void;
  cancelRide: (rideId: string) => void;
  completeRide: (rideId: string) => void;
  updateCurrentUser: (newUser: User) => void;
  cancelRequest: (rideId: string, email: string) => void;
  login: (user: User) => void;
  logout: () => void;
}

const RidesContext = createContext<RidesContextType | undefined>(undefined);

export const defaultUser: User = {
  name: "Daksh Karangiya",
  photo: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
  phone: "9876543210",
  email: "daksh.k@autoshare.com",
  gender: "Male"
};

export const presetUsers: User[] = [
  defaultUser,
  {
    name: "Aarav Sharma",
    photo: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
    phone: "9912345678",
    email: "aarav@itpark.com",
    gender: "Male"
  },
  {
    name: "Priya Patel",
    photo: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
    phone: "9823456789",
    email: "priya@gmail.com",
    gender: "Female"
  },
  {
    name: "Rohan Das",
    photo: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
    phone: "9734567890",
    email: "rohan.das@gmail.com",
    gender: "Male"
  },
  {
    name: "Sneha Reddy",
    photo: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
    phone: "9645678901",
    email: "sneha.r@university.edu",
    gender: "Female"
  }
];

// Keep this static default export for legacy imports
export const currentUser = defaultUser;

const initialRides: Ride[] = [
  {
    id: "ride-1",
    pickup: "Central Metro Station",
    destination: "Techno IT Park",
    departureTime: "Today, 05:45 PM",
    departureTimestamp: Date.now() + 2 * 60 * 60 * 1000,
    seatsTotal: 3,
    seatsLeft: 3,
    fareEstimate: "₹40 - ₹60",
    notes: "Sharing an AC cab. Quiet ride, standard luggage allowed.",
    status: "Pending",
    poster: {
      name: "Aarav Sharma",
      photo: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
      phone: "9912345678",
      email: "aarav@itpark.com",
      gender: "Male"
    },
    acceptor: null,
    requests: [],
    genderPreference: "Boys only"
  },
  {
    id: "ride-2",
    pickup: "Greenwood Apartments",
    destination: "City Shopping Mall",
    departureTime: "Today, 07:15 PM",
    departureTimestamp: Date.now() + 4 * 60 * 60 * 1000,
    seatsTotal: 2,
    seatsLeft: 1,
    fareEstimate: "₹30 - ₹40",
    notes: "Taking an auto. Only pool if you're fine with open air.",
    status: "Accepted",
    poster: {
      name: "Priya Patel",
      photo: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
      phone: "9823456789",
      email: "priya@gmail.com",
      gender: "Female"
    },
    acceptor: defaultUser,
    requests: [
      {
        id: "req-mock-1",
        user: defaultUser,
        status: "Accepted",
        timestamp: "6:50 PM"
      }
    ],
    genderPreference: "Girls only"
  },
  {
    id: "ride-3",
    pickup: "International Airport T2",
    destination: "Downtown Core",
    departureTime: "Tomorrow, 08:30 AM",
    departureTimestamp: Date.now() + 20 * 60 * 60 * 1000,
    seatsTotal: 3,
    seatsLeft: 3,
    fareEstimate: "₹250 - ₹300",
    notes: "Ola Prime Sedan. Have space for luggage. AC will be on.",
    status: "Pending",
    poster: {
      name: "Rohan Das",
      photo: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
      phone: "9734567890",
      email: "rohan.das@gmail.com",
      gender: "Male"
    },
    acceptor: null,
    requests: [],
    genderPreference: "Both"
  },
  {
    id: "ride-4",
    pickup: "University North Campus",
    destination: "Sports Complex",
    departureTime: "Tomorrow, 02:00 PM",
    departureTimestamp: Date.now() + 25 * 60 * 60 * 1000,
    seatsTotal: 1,
    seatsLeft: 1,
    fareEstimate: "₹20 - ₹30",
    notes: "Quick auto ride, looking for 1 co-passenger to split.",
    status: "Pending",
    poster: {
      name: "Sneha Reddy",
      photo: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
      phone: "9645678901",
      email: "sneha.r@university.edu",
      gender: "Female"
    },
    acceptor: null,
    requests: [],
    genderPreference: "Girls only"
  },
  {
    id: "ride-5",
    pickup: "Tech Park Phase 1",
    destination: "Metro Station Gate 3",
    departureTime: "Yesterday, 06:00 PM",
    departureTimestamp: Date.now() - 18 * 60 * 60 * 1000,
    seatsTotal: 3,
    seatsLeft: 2,
    fareEstimate: "₹50",
    notes: "Cab pool, completed yesterday.",
    status: "Completed",
    poster: defaultUser,
    acceptor: {
      name: "Aarav Sharma",
      photo: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
      phone: "9912345678",
      email: "aarav@itpark.com",
      gender: "Male"
    },
    requests: [
      {
        id: "req-mock-2",
        user: {
          name: "Aarav Sharma",
          photo: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
          phone: "9912345678",
          email: "aarav@itpark.com",
          gender: "Male"
        },
        status: "Accepted",
        timestamp: "5:50 PM"
      }
    ],
    genderPreference: "Both"
  }
];

const initialFilters: Filters = {
  pickup: '',
  destination: '',
  seats: null,
  timeSlot: 'all'
};

export const RidesProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [rides, setRides] = useState<Ride[]>(initialRides);
  const [filters, setFilters] = useState<Filters>(initialFilters);

  const clearFilters = () => {
    setFilters(initialFilters);
  };

  const login = (newUser: User) => {
    setUser(newUser);
  };

  const logout = () => {
    setUser(null);
  };

  const updateCurrentUser = (newUser: User) => {
    if (!user) return;
    setUser(newUser);
    // Sync across active rides database
    setRides(prev => prev.map(ride => {
      let updatedRide = { ...ride };
      let changed = false;

      // If user is host/poster
      if (ride.poster.email === user.email || ride.poster.name === user.name) {
        updatedRide.poster = newUser;
        changed = true;
      }
      
      // If user is acceptor
      if (ride.acceptor && (ride.acceptor.email === user.email || ride.acceptor.name === user.name)) {
        updatedRide.acceptor = newUser;
        changed = true;
      }

      // Sync user inside requests
      if (ride.requests && ride.requests.length > 0) {
        updatedRide.requests = ride.requests.map(req => {
          if (req.user.email === user.email) {
            return { ...req, user: newUser };
          }
          return req;
        });
        changed = true;
      }

      return changed ? updatedRide : ride;
    }));
  };

  const addRide = (newRideData: Omit<Ride, 'id' | 'status' | 'poster' | 'acceptor' | 'requests'>) => {
    if (!user) return;
    const newRide: Ride = {
      ...newRideData,
      id: `ride-${Date.now()}`,
      status: 'Pending',
      poster: user,
      acceptor: null,
      requests: []
    };
    setRides(prev => [newRide, ...prev]);
  };

  const requestToJoin = (rideId: string) => {
    if (!user) return;
    setRides(prev => prev.map(ride => {
      if (ride.id === rideId) {
        const alreadyRequested = ride.requests.some(r => r.user.email === user.email);
        if (alreadyRequested) return ride;

        const newRequest: RideRequest = {
          id: `req-${Date.now()}`,
          user,
          status: 'Pending',
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };
        return {
          ...ride,
          requests: [...ride.requests, newRequest]
        };
      }
      return ride;
    }));
  };

  const acceptRequest = (rideId: string, requestId: string) => {
    setRides(prev => prev.map(ride => {
      if (ride.id === rideId) {
        const targetReq = ride.requests.find(r => r.id === requestId);
        if (!targetReq) return ride;

        // Update all other requests to declined, target to accepted
        const updatedRequests = ride.requests.map(r => {
          if (r.id === requestId) return { ...r, status: 'Accepted' as const };
          if (r.status === 'Pending') return { ...r, status: 'Declined' as const };
          return r;
        });

        return {
          ...ride,
          seatsLeft: Math.max(0, ride.seatsLeft - 1),
          status: 'Accepted',
          acceptor: targetReq.user,
          requests: updatedRequests
        };
      }
      return ride;
    }));
  };

  const declineRequest = (rideId: string, requestId: string) => {
    setRides(prev => prev.map(ride => {
      if (ride.id === rideId) {
        const updatedRequests = ride.requests.map(r => {
          if (r.id === requestId) return { ...r, status: 'Declined' as const };
          return r;
        });
        return {
          ...ride,
          requests: updatedRequests
        };
      }
      return ride;
    }));
  };

  const cancelRide = (rideId: string) => {
    setRides(prev => prev.map(ride => {
      if (ride.id === rideId) {
        return {
          ...ride,
          status: 'Cancelled',
          seatsLeft: ride.seatsTotal
        };
      }
      return ride;
    }));
  };

  const completeRide = (rideId: string) => {
    setRides(prev => prev.map(ride => {
      if (ride.id === rideId) {
        return {
          ...ride,
          status: 'Completed'
        };
      }
      return ride;
    }));
  };

  const cancelRequest = (rideId: string, email: string) => {
    setRides(prev => prev.map(ride => {
      if (ride.id === rideId) {
        const isCurrentlyAccepted = ride.status === 'Accepted' && ride.acceptor?.email === email;
        const newStatus = isCurrentlyAccepted ? 'Pending' as const : ride.status;
        const newSeatsLeft = isCurrentlyAccepted ? Math.min(ride.seatsTotal, ride.seatsLeft + 1) : ride.seatsLeft;
        const newAcceptor = isCurrentlyAccepted ? null : ride.acceptor;

        const updatedRequests = ride.requests
          .filter(r => r.user.email !== email)
          .map(r => {
            if (isCurrentlyAccepted && r.status === 'Declined') {
              return { ...r, status: 'Pending' as const };
            }
            return r;
          });

        return {
          ...ride,
          status: newStatus,
          seatsLeft: newSeatsLeft,
          acceptor: newAcceptor,
          requests: updatedRequests
        };
      }
      return ride;
    }));
  };

  return (
    <RidesContext.Provider value={{
      rides,
      currentUser: user,
      filters,
      setFilters,
      clearFilters,
      addRide,
      requestToJoin,
      acceptRequest,
      declineRequest,
      cancelRide,
      completeRide,
      updateCurrentUser,
      cancelRequest,
      login,
      logout
    }}>
      {children}
    </RidesContext.Provider>
  );
};

export const useRides = () => {
  const context = useContext(RidesContext);
  if (!context) {
    throw new Error('useRides must be used within a RidesProvider');
  }
  return context;
};
